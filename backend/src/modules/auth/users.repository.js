'use strict';

// The only place `users/{uid}` is read or written — see docs/03_DATABASE_DESIGN.md § 4.10,
// docs/21_BACKEND_GUIDELINES.md § 4.

const { getDb } = require('../../firebase/admin');

/**
 * @param {string} uid
 * @returns {Promise<object|null>}
 */
async function get(uid) {
  const snapshot = await getDb().ref(`users/${uid}`).once('value');
  return snapshot.val();
}

/**
 * @param {string} uid
 * @param {object} profile
 * @returns {Promise<object>}
 */
async function create(uid, profile) {
  await getDb().ref(`users/${uid}`).set(profile);
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

module.exports = { get, create, update };
