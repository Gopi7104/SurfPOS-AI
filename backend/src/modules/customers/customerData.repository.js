'use strict';

// The only place `customerData/{merchantId}/{customers,purchases}` is read or written — mirrors
// modules/inventory/product.repository.js's DI/shape exactly. Entirely Firebase-owned.
//
// Each list is stored and returned as one whole JSON array — the same "read-modify-write-the-
// whole-list" shape the Flutter app's CustomerLocalStorage/CustomerPurchaseLocalStorage used
// locally before this module existed, just relocated to Firebase RTDB so it survives logout/
// reinstall/a new device instead of living only in one device's secure storage.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createCustomerDataRepository({ getDb = defaultGetDb } = {}) {
  /** @param {string} merchantId */
  async function getCustomers(merchantId) {
    const snapshot = await getDb().ref(`customerData/${merchantId}/customers`).once('value');
    return snapshot.val() || [];
  }

  /**
   * @param {string} merchantId
   * @param {object[]} customers
   */
  async function setCustomers(merchantId, customers) {
    await getDb().ref(`customerData/${merchantId}/customers`).set(customers);
    return customers;
  }

  /** @param {string} merchantId */
  async function getPurchases(merchantId) {
    const snapshot = await getDb().ref(`customerData/${merchantId}/purchases`).once('value');
    return snapshot.val() || [];
  }

  /**
   * @param {string} merchantId
   * @param {object[]} purchases
   */
  async function setPurchases(merchantId, purchases) {
    await getDb().ref(`customerData/${merchantId}/purchases`).set(purchases);
    return purchases;
  }

  return { getCustomers, setCustomers, getPurchases, setPurchases };
}

module.exports = createCustomerDataRepository();
module.exports.createCustomerDataRepository = createCustomerDataRepository;
