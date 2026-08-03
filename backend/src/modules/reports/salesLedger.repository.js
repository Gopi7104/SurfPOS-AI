'use strict';

// The only place `salesLedger/{merchantId}` is read or written — mirrors
// modules/customers/customerData.repository.js exactly. Entirely Firebase-owned.
//
// Stored/returned as one whole JSON array — the same shape the Flutter app's
// SalesLedgerLocalStorage used locally, just relocated to Firebase RTDB so Dashboard/Reports
// data survives logout/reinstall/a new device instead of living only on one device.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createSalesLedgerRepository({ getDb = defaultGetDb } = {}) {
  /** @param {string} merchantId */
  async function getSales(merchantId) {
    const snapshot = await getDb().ref(`salesLedger/${merchantId}`).once('value');
    return snapshot.val() || [];
  }

  /**
   * @param {string} merchantId
   * @param {object[]} records
   */
  async function setSales(merchantId, records) {
    await getDb().ref(`salesLedger/${merchantId}`).set(records);
    return records;
  }

  return { getSales, setSales };
}

module.exports = createSalesLedgerRepository();
module.exports.createSalesLedgerRepository = createSalesLedgerRepository;
