'use strict';

// Inventory Management (Roadmap Phase 7, docs/22_DEVELOPMENT_ROADMAP.md) — product catalog +
// per-store stock levels. Entirely Firebase-owned; never calls the Surfboard SDK. `merchantId`
// (for the product catalog) and `storeId` ownership (for stock adjustments) are resolved via
// cross-module Service calls (docs/21_BACKEND_GUIDELINES.md § 8) rather than reaching into
// modules/merchant/ or modules/store/'s Repositories directly — same pattern as
// docs/08_ARCHITECTURE_DECISIONS.md §§ ADR-022/ADR-023.

const { MESSAGES } = require('../../constants');
const { NotFoundError, ConflictError, InsufficientStockError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultProductRepository = require('./product.repository');
const defaultStockRepository = require('./stock.repository');
const defaultMerchantService = require('../merchant/merchant.service');
const defaultStoreService = require('../store/store.service');

const STOCK_AWARE_LIMIT_DEFAULT = 20;
const STOCK_AWARE_LIMIT_MAX = 100;

/**
 * @param {{ productRepository?: object, stockRepository?: object, merchantService?: object, storeService?: object, logger?: object }} [deps]
 */
function createInventoryService({
  productRepository = defaultProductRepository,
  stockRepository = defaultStockRepository,
  merchantService = defaultMerchantService,
  storeService = defaultStoreService,
  logger = defaultLogger,
} = {}) {
  async function getOwnedProduct(merchantId, productId) {
    const product = await productRepository.get(merchantId, productId);
    if (!product) {
      throw new NotFoundError(MESSAGES.PRODUCT_NOT_FOUND);
    }
    return product;
  }

  /** Throws ConflictError if another active product already uses this SKU for this merchant. */
  async function assertSkuAvailable(merchantId, sku, excludeProductId) {
    const existing = await productRepository.findBySku(merchantId, sku, excludeProductId);
    if (existing) {
      throw new ConflictError(MESSAGES.DUPLICATE_SKU);
    }
  }

  /**
   * Resolves which store's stock to attach to product reads: the given `storeId` (after verifying
   * the caller owns it) or, if none was given, the caller's first registered store — see
   * `storeService.getPrimaryStoreId`. Returns null for a merchant with no store yet; product reads
   * then report `stockQuantity: 0` rather than failing (no store means nothing has been stocked).
   * @param {string} uid
   * @param {string} [requestedStoreId]
   */
  async function resolveStoreId(uid, requestedStoreId) {
    if (requestedStoreId) {
      await storeService.verifyStoreOwnership(uid, requestedStoreId);
      return requestedStoreId;
    }
    return storeService.getPrimaryStoreId(uid);
  }

  async function hydrateStock(storeId, product) {
    if (!storeId) {
      return { ...product, stockQuantity: 0 };
    }
    const stock = await stockRepository.get(storeId, product.id);
    return { ...product, stockQuantity: stock?.quantity ?? 0 };
  }

  /**
   * @param {string} uid
   * @param {object} input product fields (name, description?, sku, barcode?, category?, unit,
   *   costPrice, sellingPrice, taxRate, discountPercentage?, supplierId?, imageUrl?,
   *   reorderLevel?, status?)
   */
  async function createProduct(uid, input) {
    const merchantId = await merchantService.getMerchantId(uid);
    await assertSkuAvailable(merchantId, input.sku);

    const now = Date.now();
    const product = await productRepository.create(merchantId, {
      ...input,
      merchantId,
      status: input.status ?? 'ACTIVE',
      discountPercentage: input.discountPercentage ?? 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    });

    logger.info({ uid, merchantId, productId: product.id }, 'Created product');
    return product;
  }

  /**
   * @param {string} uid
   * @param {string} productId
   * @param {{ storeId?: string }} [options] which store's stock to attach; defaults to the
   *   caller's primary store (see [resolveStoreId])
   */
  async function getProduct(uid, productId, { storeId } = {}) {
    const merchantId = await merchantService.getMerchantId(uid);
    const product = await getOwnedProduct(merchantId, productId);
    const resolvedStoreId = await resolveStoreId(uid, storeId);
    return hydrateStock(resolvedStoreId, product);
  }

  /**
   * @param {string} uid
   * @param {string} productId
   * @param {object} patch partial product fields
   */
  async function updateProduct(uid, productId, patch) {
    const merchantId = await merchantService.getMerchantId(uid);
    await getOwnedProduct(merchantId, productId);
    if (patch.sku) {
      await assertSkuAvailable(merchantId, patch.sku, productId);
    }
    const updated = await productRepository.update(merchantId, productId, {
      ...patch,
      updatedAt: Date.now(),
    });

    logger.info({ uid, merchantId, productId }, 'Updated product');
    return updated;
  }

  /**
   * Soft delete — sets isActive: false, never removes the record.
   * @param {string} uid
   * @param {string} productId
   */
  async function softDeleteProduct(uid, productId) {
    const merchantId = await merchantService.getMerchantId(uid);
    await getOwnedProduct(merchantId, productId);
    const updated = await productRepository.update(merchantId, productId, {
      isActive: false,
      updatedAt: Date.now(),
    });

    logger.info({ uid, merchantId, productId }, 'Soft-deleted product');
    return updated;
  }

  /**
   * Every returned product carries a `stockQuantity` (hydrated from the resolved store's stock
   * record) alongside its catalog fields. `stockFilter`/`sortBy: 'stock'` require reading the
   * merchant's *entire* filtered catalog to hydrate+filter/sort before pagination can happen — see
   * [listWithStockAwareness] — every other query stays on the cheap paginate-first path.
   * @param {string} uid
   * @param {{ search?: string, category?: string, barcode?: string, status?: string, includeInactive?: boolean, stockFilter?: 'lowStock'|'inStock'|'outOfStock', sortBy?: 'name'|'price'|'stock'|'updatedAt'|'createdAt', sortOrder?: 'asc'|'desc', storeId?: string, limit?: number, cursor?: string }} [query]
   */
  async function listProducts(uid, query = {}) {
    const merchantId = await merchantService.getMerchantId(uid);
    const { stockFilter, sortBy, sortOrder, storeId, limit, cursor, ...catalogFilters } = query;
    const resolvedStoreId = await resolveStoreId(uid, storeId);

    if (stockFilter || sortBy === 'stock') {
      return listWithStockAwareness(merchantId, resolvedStoreId, {
        ...catalogFilters,
        stockFilter,
        sortBy,
        sortOrder,
        limit,
        cursor,
      });
    }

    const { items, nextCursor } = await productRepository.list(merchantId, {
      ...catalogFilters,
      sortBy,
      sortOrder,
      limit,
      cursor,
    });
    const hydrated = await Promise.all(items.map((product) => hydrateStock(resolvedStoreId, product)));
    return { items: hydrated, nextCursor };
  }

  async function listWithStockAwareness(
    merchantId,
    storeId,
    { stockFilter, sortBy, sortOrder, limit = STOCK_AWARE_LIMIT_DEFAULT, cursor, ...catalogFilters },
  ) {
    const boundedLimit = Math.min(Math.max(limit, 1), STOCK_AWARE_LIMIT_MAX);
    const catalog = await productRepository.listAll(merchantId, catalogFilters);
    let hydrated = await Promise.all(catalog.map((product) => hydrateStock(storeId, product)));

    if (stockFilter === 'lowStock') {
      hydrated = hydrated.filter(
        (product) => product.stockQuantity > 0 && product.stockQuantity <= (product.reorderLevel ?? 0),
      );
    } else if (stockFilter === 'inStock') {
      hydrated = hydrated.filter((product) => product.stockQuantity > 0);
    } else if (stockFilter === 'outOfStock') {
      hydrated = hydrated.filter((product) => product.stockQuantity === 0);
    }

    if (sortBy === 'stock') {
      const direction = sortOrder === 'desc' ? -1 : 1;
      hydrated.sort((a, b) => (a.stockQuantity - b.stockQuantity) * direction || a.id.localeCompare(b.id));
    }

    const startIndex = cursor ? hydrated.findIndex((product) => product.id === cursor) + 1 : 0;
    const page = hydrated.slice(startIndex, startIndex + boundedLimit);
    const nextCursor = startIndex + boundedLimit < hydrated.length ? page[page.length - 1].id : null;

    return { items: page, nextCursor };
  }

  /**
   * @param {string} uid
   * @param {string} productId
   * @param {{ storeId: string, quantityDelta: number, reason?: string }} input
   */
  async function adjustStock(uid, productId, { storeId, quantityDelta, reason }) {
    const merchantId = await merchantService.getMerchantId(uid);
    await getOwnedProduct(merchantId, productId);
    await storeService.verifyStoreOwnership(uid, storeId);

    const updated = await stockRepository.adjustQuantity(storeId, productId, quantityDelta, uid);
    if (!updated) {
      throw new InsufficientStockError();
    }

    logger.info({ uid, storeId, productId, quantityDelta, reason }, 'Adjusted stock');
    return updated;
  }

  return { createProduct, getProduct, updateProduct, softDeleteProduct, listProducts, adjustStock };
}

module.exports = createInventoryService();
module.exports.createInventoryService = createInventoryService;
