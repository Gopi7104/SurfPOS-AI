'use strict';

// The only place `users/{uid}` is read or written — see docs/03_DATABASE_DESIGN.md § 4.10,
// docs/21_BACKEND_GUIDELINES.md § 4.
//
// `users_by_email/{emailKey}` is a secondary index (email -> uid) so a Firebase account signing
// in under a different provider than the one that originally created the profile (e.g. Google,
// after the profile was created via Email/Password) can still be resolved to the same profile —
// see auth.service.js#resolveProfileForToken. RTDB keys can't contain '.', so the email is
// base64url-encoded rather than used as a literal path segment.

const { getDb } = require('../../firebase/admin');

/**
 * @param {string} email
 * @returns {string}
 */
function emailKey(email) {
  return Buffer.from(email.trim().toLowerCase(), 'utf8').toString('base64url');
}

/**
 * @param {string} uid
 * @returns {Promise<object|null>}
 */
async function get(uid) {
  const snapshot = await getDb().ref(`users/${uid}`).once('value');
  return snapshot.val();
}

/**
 * @param {string} email
 * @returns {Promise<string|null>}
 */
async function getUidByEmail(email) {
  const snapshot = await getDb()
    .ref(`users_by_email/${emailKey(email)}`)
    .once('value');
  return snapshot.val();
}

/**
 * @param {string} uid
 * @param {object} profile
 * @returns {Promise<object>}
 */
async function create(uid, profile) {
  const updates = { [`users/${uid}`]: profile };
  if (profile.email) {
    updates[`users_by_email/${emailKey(profile.email)}`] = uid;
  }
  await getDb().ref().update(updates);
  return profile;
}

/**
 * @param {string} uid
 * @param {object} patch
 * @returns {Promise<object|null>}
 */
async function update(uid, patch) {
  const ref = getDb().ref(`users/${uid}`);
  await ref.update(patch);
  const snapshot = await ref.once('value');
  return snapshot.val();
}

module.exports = { get, getUidByEmail, create, update };
