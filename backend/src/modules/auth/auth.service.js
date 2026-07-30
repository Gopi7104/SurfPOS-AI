'use strict';

// Application-user identity — Firebase Auth + `users/{uid}` profile only (docs/05_FEATURES.md §
// 2). Never creates a Merchant/Store/Surfboard record — that's Phase 4's `POST /auth/register`
// orchestration (see docs/22_DEVELOPMENT_ROADMAP.md) — and never calls the Surfboard SDK.

const { getAuth } = require('../../firebase/admin');
const { ROLES, MESSAGES } = require('../../constants');
const { ValidationError, ConflictError, NotFoundError, UnauthenticatedError } = require('../../utils/errors');
const { logger } = require('../../utils/logger');
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

  /**
   * A Firebase UID is per sign-in-provider, not per person — the same human signing in with
   * Google gets a different uid than the one their Email/Password account was created under,
   * and Firebase does not merge these automatically (this project has Email Enumeration
   * Protection enabled, so Firebase won't even surface `auth/account-exists-with-different-
   * credential` to warn about it — see docs/15_SURFBOARD_INTEGRATION.md's auth notes). Resolving
   * by uid first (the common, fast case) and falling back to the email index lets a second
   * provider for the same address reach the one profile that already exists instead of 404ing.
   * @param {{ uid: string, email?: string|null }} identity
   * @returns {Promise<object|null>}
   */
  async function resolveProfileForToken({ uid, email }) {
    const byUid = await usersRepository.get(uid);
    if (byUid) {
      return byUid;
    }
    if (!email) {
      return null;
    }
    const canonicalUid = await usersRepository.getUidByEmail(email);
    return canonicalUid ? usersRepository.get(canonicalUid) : null;
  }

  /** @param {string} idToken */
  async function login(idToken) {
    const decodedToken = await verifyToken(idToken);
    const signInProvider = decodedToken.firebase?.sign_in_provider;
    logger.info(
      {
        uid: decodedToken.uid,
        email: decodedToken.email,
        signInProvider,
        identities: decodedToken.firebase?.identities,
      },
      'Firebase ID token verified for login',
    );

    let profile = await resolveProfileForToken({ uid: decodedToken.uid, email: decodedToken.email });

    if (!profile && signInProvider && signInProvider !== 'password') {
      // A federated (e.g. Google) sign-in with no existing profile under this uid or its email
      // is a genuinely new user — auto-provision rather than 404, since there's no client-only
      // way to "sign up" a federated account (see AuthRepositoryImpl.logInWithGoogle on the
      // frontend). Password accounts are deliberately excluded: those are always created via an
      // explicit POST /auth/signup first, so an unresolvable password uid means the profile was
      // removed out-of-band, not that signup was skipped.
      const now = Date.now();
      profile = {
        uid: decodedToken.uid,
        email: decodedToken.email || null,
        displayName: decodedToken.name || null,
        role: ROLES.OWNER,
        status: DEFAULT_STATUS,
        createdAt: now,
        updatedAt: now,
      };
      await usersRepository.create(decodedToken.uid, profile);
      logger.info(
        { uid: decodedToken.uid, signInProvider },
        'Auto-provisioned profile for federated sign-in',
      );
    }

    if (!profile) {
      throw new NotFoundError(MESSAGES.USER_PROFILE_NOT_FOUND);
    }
    return profile;
  }

  /** @param {{ uid: string, email?: string|null }} identity */
  async function getCurrentUser({ uid, email }) {
    const profile = await resolveProfileForToken({ uid, email });
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
