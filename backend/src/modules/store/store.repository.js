'use strict';

// The only place `storeReferences/{uid}/{storeId}` is read or written — see
// docs/03_DATABASE_DESIGN.md § 4.12, docs/21_BACKEND_GUIDELINES.md § 4. This is a genuinely new
// Firebase-owned node (not shared with any other repository), so — unlike
// modules/merchant/merchant.repository.js — this one calls `getDb()` directly rather than
// composing another repository.
//
// A minimal local registry of which storeIds SurfPOS itself created for a given uid — never the
// full Store object (docs/20_DOMAIN_MODEL.md § 1). It exists because Surfboard's docs don't
// confirm a list-stores-by-merchant endpoint (docs/08_ARCHITECTURE_DECISIONS.md § ADR-023); this
// registry is what `GET /stores` enumerates before hydrating each entry with a live Surfboard call.
//
// Takes its Firebase accessor as a DI parameter (docs/21_BACKEND_GUIDELINES.md § 12) for the same
// reason modules/merchant/merchantApplication.repository.js does — a real "Repository behavior"
// unit-test seam, given this project's Vitest/CJS `vi.mock()` limitation (see ADR-020).

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createStoreRepository({ getDb = defaultGetDb } = {}) {
  /**
   * @param {string} uid
   * @param {string} storeId
   * @param {{ merchantId: string }} meta
   * @returns {Promise<object>} the persisted reference
   */
  async function addReference(uid, storeId, { merchantId }) {
    const reference = { storeId, merchantId, createdAt: Date.now() };
    await getDb().ref(`storeReferences/${uid}/${storeId}`).set(reference);
    return reference;
  }

  /**
   * @param {string} uid
   * @param {string} storeId
   * @returns {Promise<boolean>} whether this uid's registry lists this storeId
   */
  async function hasReference(uid, storeId) {
    const snapshot = await getDb().ref(`storeReferences/${uid}/${storeId}`).once('value');
    return snapshot.val() !== null;
  }

  /**
   * @param {string} uid
   * @returns {Promise<string[]>} every storeId registered for this uid
   */
  async function listReferences(uid) {
    const snapshot = await getDb().ref(`storeReferences/${uid}`).once('value');
    const references = snapshot.val() || {};
    return Object.keys(references);
  }

  return { addReference, hasReference, listReferences };
}

module.exports = createStoreRepository();
module.exports.createStoreRepository = createStoreRepository;
