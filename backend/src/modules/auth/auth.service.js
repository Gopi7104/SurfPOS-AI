'use strict';

// Application-user identity — Firebase Auth + `users/{uid}` profile only (docs/05_FEATURES.md §
// 2). Never creates a Merchant/Store/Surfboard record — that's Phase 4's `POST /auth/register`
// orchestration (see docs/22_DEVELOPMENT_ROADMAP.md) — and never calls the Surfboard SDK.

const { getAuth } = require('../../firebase/admin');
const { ROLES, MESSAGES } = require('../../constants');
const { ValidationError, ConflictError, NotFoundError, UnauthenticatedError } = require('../../utils/errors');
const defaultUsersRepository = require('./users.repository');

const DEFAULT_STATUS = 'active';

// Maps a known Firebase Admin Auth error code to the typed AppError it should surface as.
// Anything not listed here propagates untouched — error.middleware.js already turns an
// unrecognized error into a generic 500/INTERNAL_ERROR (docs/21_BACKEND_GUIDELINES.md § 9).
const FIREBASE_ERROR_MAP = {
  'auth/email-already-exists': () => new ConflictError(MESSAGES.EMAIL_ALREADY_IN_USE),
  'auth/invalid-password': (error) => new ValidationError(error.message),
  'auth/invalid-email': (error) => new ValidationError(error.message),
};

function mapFirebaseAuthError(error) {
  const factory = FIREBASE_ERROR_MAP[error.code];
  return factory ? factory(error) : error;
}

/**
 * @param {{ firebaseAuth?: object, usersRepository?: object }} [deps]
 */
function createAuthService({
  firebaseAuth: injectedFirebaseAuth,
  usersRepository = defaultUsersRepository,
} = {}) {
  function resolveFirebaseAuth() {
    return injectedFirebaseAuth || getAuth();
  }

  /** @param {string} idToken */
  async function verifyToken(idToken) {
    try {
      return await resolveFirebaseAuth().verifyIdToken(idToken);
    } catch {
      throw new UnauthenticatedError(MESSAGES.INVALID_TOKEN);
    }
  }

  /** @param {{ email: string, password: string, displayName?: string }} input */
  async function signUp({ email, password, displayName }) {
    let userRecord;
    try {
      userRecord = await resolveFirebaseAuth().createUser({ email, password, displayName });
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }

    const now = Date.now();
    const profile = {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: displayName || null,
      role: ROLES.OWNER,
      status: DEFAULT_STATUS,
      createdAt: now,
      updatedAt: now,
    };

    await usersRepository.create(userRecord.uid, profile);
    return profile;
  }

  /** @param {string} idToken */
  async function login(idToken) {
    const decodedToken = await verifyToken(idToken);
    const profile = await usersRepository.get(decodedToken.uid);
    if (!profile) {
      throw new NotFoundError(MESSAGES.USER_PROFILE_NOT_FOUND);
    }
    return profile;
  }

  /** @param {string} uid */
  async function getCurrentUser(uid) {
    const profile = await usersRepository.get(uid);
    if (!profile) {
      throw new NotFoundError(MESSAGES.USER_PROFILE_NOT_FOUND);
    }
    return profile;
  }

  /**
   * Revokes the user's refresh tokens. Already-issued ID tokens remain valid until they expire
   * naturally (Firebase ID tokens are short-lived, ~1h) — full immediate invalidation would
   * require `checkRevoked: true` on every verifyIdToken call, an extra round trip per request
   * this phase doesn't need.
   * @param {string} uid
   */
  async function logout(uid) {
    await resolveFirebaseAuth().revokeRefreshTokens(uid);
    return { uid, loggedOut: true };
  }

  return { verifyToken, signUp, login, getCurrentUser, logout };
}

module.exports = createAuthService();
module.exports.createAuthService = createAuthService;
