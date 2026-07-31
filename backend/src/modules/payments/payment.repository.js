'use strict';

// The only place `onlineTerminals/{storeId}` is read or written. Caches the software-only online
// terminalId Surfboard assigns a store the first time it takes a payment (see
// payment.service.js#getOrCreateTerminalId) — registering one is a one-time setup per store, not
// a per-checkout call, so it's cached the same way modules/store/store.repository.js caches which
// storeIds SurfPOS created.
//
// Takes its Firebase accessor as a DI parameter (docs/21_BACKEND_GUIDELINES.md § 12), same as
// every other Repository in this codebase.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createPaymentRepository({ getDb = defaultGetDb } = {}) {
  /**
   * @param {string} storeId
   * @returns {Promise<string|null>}
   */
  async function getTerminalId(storeId) {
    const snapshot = await getDb().ref(`onlineTerminals/${storeId}`).once('value');
    return snapshot.val()?.terminalId ?? null;
  }

  /**
   * @param {string} storeId
   * @param {string} terminalId
   */
  async function setTerminalId(storeId, terminalId) {
    await getDb().ref(`onlineTerminals/${storeId}`).set({ terminalId, createdAt: Date.now() });
  }

  return { getTerminalId, setTerminalId };
}

module.exports = createPaymentRepository();
module.exports.createPaymentRepository = createPaymentRepository;
