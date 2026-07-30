'use strict';

// The only place `inventory/{storeId}/{productId}` is read or written — see
// docs/03_DATABASE_DESIGN.md § 4.2, docs/21_BACKEND_GUIDELINES.md § 4. Entirely Firebase-owned;
// never calls the Surfboard SDK.
//
// adjustQuantity() mirrors the transaction pattern from docs/21_BACKEND_GUIDELINES.md § 4's own
// worked example, extended to (a) lazily create the record on a store's first restock of a
// product (upsert), and (b) abort the transaction — never letting quantity go negative — when a
// reduction would exceed what's available.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createStockRepository({ getDb = defaultGetDb } = {}) {
  /**
   * @param {string} storeId
   * @param {string} productId
   * @returns {Promise<object|null>}
   */
  async function get(storeId, productId) {
    const snapshot = await getDb().ref(`inventory/${storeId}/${productId}`).once('value');
    return snapshot.val();
  }

  /**
   * @param {string} storeId
   * @param {string} productId
   * @param {number} delta positive to restock, negative to deduct
   * @param {string} updatedBy Firebase Auth uid making the adjustment
   * @returns {Promise<object|null>} the resulting record, or null if the transaction aborted
   *   (would have gone negative, or reduced a record that doesn't exist yet)
   */
  async function adjustQuantity(storeId, productId, delta, updatedBy) {
    const ref = getDb().ref(`inventory/${storeId}/${productId}`);
    const now = Date.now();

    const { committed, snapshot } = await ref.transaction((current) => {
      if (!current) {
        if (delta < 0) {
          return undefined;
        }
        return {
          productId,
          storeId,
          quantity: delta,
          reorderLevel: 0,
          lastRestockedAt: now,
          lastUpdatedBy: updatedBy,
        };
      }

      const nextQuantity = current.quantity + delta;
      if (nextQuantity < 0) {
        return undefined;
      }

      return {
        ...current,
        quantity: nextQuantity,
        lastUpdatedBy: updatedBy,
        ...(delta > 0 ? { lastRestockedAt: now } : {}),
      };
    });

    return committed ? snapshot.val() : null;
  }

  return { get, adjustQuantity };
}

module.exports = createStockRepository();
module.exports.createStockRepository = createStockRepository;
