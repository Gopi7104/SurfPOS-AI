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

  /** @param {string} merchantId */
  async function getAll(merchantId) {
    const snapshot = await getDb().ref(`products/${merchantId}`).once('value');
    const all = snapshot.val() || {};
    return Object.values(all);
  }

  /**
   * SKU uniqueness is per-merchant, checked against active products only — a soft-deleted
   * product's SKU may be reused by a new product.
   * @param {string} merchantId
   * @param {string} sku
   * @param {string} [excludeProductId] skip this id — used when a product keeps its own sku on update
   * @returns {Promise<object|null>}
   */
  async function findBySku(merchantId, sku, excludeProductId) {
    const items = await getAll(merchantId);
    return (
      items.find((product) => product.isActive && product.sku === sku && product.id !== excludeProductId) ??
      null
    );
  }

  function applyFilters(items, { search, category, barcode, status, includeInactive = false }) {
    let result = items;
    if (!includeInactive) {
      result = result.filter((product) => product.isActive);
    }
    if (category) {
      result = result.filter((product) => product.category === category);
    }
    if (status) {
      result = result.filter((product) => product.status === status);
    }
    if (barcode) {
      result = result.filter((product) => product.barcode === barcode);
    }
    if (search) {
      const term = search.toLowerCase();
      result = result.filter(
        (product) =>
          product.name?.toLowerCase().includes(term) ||
          product.sku?.toLowerCase().includes(term) ||
          product.barcode?.toLowerCase().includes(term),
      );
    }
    return result;
  }

  const SORT_KEYS = {
    name: (product) => product.name?.toLowerCase() ?? '',
    price: (product) => product.sellingPrice ?? 0,
    updatedAt: (product) => product.updatedAt ?? 0,
    createdAt: (product) => product.createdAt ?? 0,
  };

  function applySort(items, { sortBy, sortOrder = 'asc' } = {}) {
    const keyOf = SORT_KEYS[sortBy];
    if (!keyOf) {
      return [...items].sort((a, b) => a.id.localeCompare(b.id));
    }
    const direction = sortOrder === 'desc' ? -1 : 1;
    return [...items].sort((a, b) => {
      const left = keyOf(a);
      const right = keyOf(b);
      if (left < right) return -1 * direction;
      if (left > right) return 1 * direction;
      return a.id.localeCompare(b.id);
    });
  }

  /**
   * Catalog-only filter + sort over the merchant's full product list, unpaginated. Exposed
   * directly (not just via [list]) so `inventory.service.js` can hydrate per-store stock and apply
   * a stock-based filter/sort *before* paginating — pagination over a stock-derived order can't
   * happen inside this Repository, since stock lives in `stock.repository.js`
   * (docs/08_ARCHITECTURE_DECISIONS.md § ADR-024).
   * @param {string} merchantId
   * @param {{ search?: string, category?: string, barcode?: string, status?: string, includeInactive?: boolean, sortBy?: string, sortOrder?: string }} [filters]
   * @returns {Promise<object[]>}
   */
  async function listAll(merchantId, filters = {}) {
    const items = await getAll(merchantId);
    return applySort(applyFilters(items, filters), filters);
  }

  /**
   * @param {string} merchantId
   * @param {{ search?: string, category?: string, barcode?: string, status?: string, includeInactive?: boolean, sortBy?: string, sortOrder?: string, limit?: number, cursor?: string }} [query]
   * @returns {Promise<{ items: object[], nextCursor: string|null }>}
   */
  async function list(merchantId, query = {}) {
    const { limit = DEFAULT_LIMIT, cursor, ...filters } = query;
    const boundedLimit = Math.min(Math.max(limit, 1), MAX_LIMIT);

    const sorted = await listAll(merchantId, filters);

    const startIndex = cursor ? sorted.findIndex((product) => product.id === cursor) + 1 : 0;
    const page = sorted.slice(startIndex, startIndex + boundedLimit);
    const nextCursor = startIndex + boundedLimit < sorted.length ? page[page.length - 1].id : null;

    return { items: page, nextCursor };
  }

  return { create, get, update, list, listAll, findBySku };
}

module.exports = createProductRepository();
module.exports.createProductRepository = createProductRepository;
