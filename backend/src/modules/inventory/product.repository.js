'use strict';

// The only place `products/{merchantId}/{productId}` is read or written — see
// docs/03_DATABASE_DESIGN.md § 4.1, docs/21_BACKEND_GUIDELINES.md § 4. Entirely Firebase-owned;
// never calls the Surfboard SDK (docs/22_DEVELOPMENT_ROADMAP.md Phase 7).
//
// Search/filter/pagination are done in-memory over the merchant's full product list rather than
// RTDB range queries — a deliberate simplification appropriate for the target small-retailer
// catalog size (docs/01_PROJECT_OVERVIEW.md), documented in docs/08_ARCHITECTURE_DECISIONS.md §
// ADR-024. Revisit with real indexing if catalog sizes grow.
//
// Takes its Firebase accessor as a DI parameter (docs/21_BACKEND_GUIDELINES.md § 12) for the same
// "Repository behavior" unit-test seam reason as modules/store/store.repository.js.

const { getDb: defaultGetDb } = require('../../firebase/admin');

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createProductRepository({ getDb = defaultGetDb } = {}) {
  /**
   * @param {string} merchantId
   * @param {object} product fields to persist (without an id yet)
   * @returns {Promise<object>} the persisted product, including its generated id
   */
  async function create(merchantId, product) {
    const ref = getDb().ref(`products/${merchantId}`).push();
    const record = { ...product, id: ref.key };
    await ref.set(record);
    return record;
  }

  /**
   * @param {string} merchantId
   * @param {string} productId
   * @returns {Promise<object|null>}
   */
  async function get(merchantId, productId) {
    const snapshot = await getDb().ref(`products/${merchantId}/${productId}`).once('value');
    return snapshot.val();
  }

  /**
   * @param {string} merchantId
   * @param {string} productId
   * @param {object} patch
   * @returns {Promise<object|null>}
   */
  async function update(merchantId, productId, patch) {
    const ref = getDb().ref(`products/${merchantId}/${productId}`);
    await ref.update(patch);
    const snapshot = await ref.once('value');
    return snapshot.val();
  }

  /**
   * @param {string} merchantId
   * @param {{ search?: string, category?: string, barcode?: string, includeInactive?: boolean, limit?: number, cursor?: string }} [query]
   * @returns {Promise<{ items: object[], nextCursor: string|null }>}
   */
  async function list(merchantId, query = {}) {
    const { search, category, barcode, includeInactive = false, limit = DEFAULT_LIMIT, cursor } = query;
    const boundedLimit = Math.min(Math.max(limit, 1), MAX_LIMIT);

    const snapshot = await getDb().ref(`products/${merchantId}`).once('value');
    const all = snapshot.val() || {};

    let items = Object.values(all);
    if (!includeInactive) {
      items = items.filter((product) => product.isActive);
    }
    if (category) {
      items = items.filter((product) => product.category === category);
    }
    if (barcode) {
      items = items.filter((product) => product.barcode === barcode);
    }
    if (search) {
      const term = search.toLowerCase();
      items = items.filter((product) => product.name?.toLowerCase().includes(term));
    }

    items.sort((a, b) => a.id.localeCompare(b.id));

    const startIndex = cursor ? items.findIndex((product) => product.id === cursor) + 1 : 0;
    const page = items.slice(startIndex, startIndex + boundedLimit);
    const nextCursor = startIndex + boundedLimit < items.length ? page[page.length - 1].id : null;

    return { items: page, nextCursor };
  }

  return { create, get, update, list };
}

module.exports = createProductRepository();
module.exports.createProductRepository = createProductRepository;
