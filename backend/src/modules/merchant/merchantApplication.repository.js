'use strict';

// The only place `merchantApplications/{uid}` is read or written — see docs/03_DATABASE_DESIGN.md
// § 4.11, docs/21_BACKEND_GUIDELINES.md § 4.
//
// Unlike most Repositories in this codebase, this one takes its Firebase accessor as a DI
// parameter (docs/21_BACKEND_GUIDELINES.md § 12) rather than calling `getDb()` as a hard-coded
// top-level import — a deliberate, documented deviation (see docs/08_ARCHITECTURE_DECISIONS.md §
// ADR-021) made specifically so "Repository persistence" has a real unit-test seam.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createMerchantApplicationRepository({ getDb = defaultGetDb } = {}) {
  /** @param {string} uid @returns {Promise<object|null>} */
  async function get(uid) {
    const snapshot = await getDb().ref(`merchantApplications/${uid}`).once('value');
    return snapshot.val();
  }

  /** @param {string} uid @param {object} application @returns {Promise<object>} */
  async function create(uid, application) {
    await getDb().ref(`merchantApplications/${uid}`).set(application);
    return application;
  }

  /** @param {string} uid @param {object} patch @returns {Promise<object|null>} */
  async function update(uid, patch) {
    const ref = getDb().ref(`merchantApplications/${uid}`);
    await ref.update(patch);
    const snapshot = await ref.once('value');
    return snapshot.val();
  }

  return { get, create, update };
}

module.exports = createMerchantApplicationRepository();
module.exports.createMerchantApplicationRepository = createMerchantApplicationRepository;
