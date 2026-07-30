'use strict';

// Inventory Management (Roadmap Phase 7, docs/22_DEVELOPMENT_ROADMAP.md) — product catalog +
// per-store stock levels. Entirely Firebase-owned; never calls the Surfboard SDK. `merchantId`
// (for the product catalog) and `storeId` ownership (for stock adjustments) are resolved via
// cross-module Service calls (docs/21_BACKEND_GUIDELINES.md § 8) rather than reaching into
// modules/merchant/ or modules/store/'s Repositories directly — same pattern as
// docs/08_ARCHITECTURE_DECISIONS.md §§ ADR-022/ADR-023.

const { MESSAGES } = require('../../constants');
const { NotFoundError, InsufficientStockError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultProductRepository = require('./product.repository');
const defaultStockRepository = require('./stock.repository');
const defaultMerchantService = require('../merchant/merchant.service');
const defaultStoreService = require('../store/store.service');

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

  /**
   * @param {string} uid
   * @param {object} input product fields (name, sku, barcode?, category?, unit, costPrice,
   *   sellingPrice, taxRate, supplierId?, imageUrl?, reorderLevel?)
   */
  async function createProduct(uid, input) {
    const merchantId = await merchantService.getMerchantId(uid);
    const now = Date.now();
    const product = await productRepository.create(merchantId, {
      ...input,
      merchantId,
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
   */
  async function getProduct(uid, productId) {
    const merchantId = await merchantService.getMerchantId(uid);
    return getOwnedProduct(merchantId, productId);
  }

  /**
   * @param {string} uid
   * @param {string} productId
   * @param {object} patch partial product fields
   */
  async function updateProduct(uid, productId, patch) {
    const merchantId = await merchantService.getMerchantId(uid);
    await getOwnedProduct(merchantId, productId);
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
   * @param {string} uid
   * @param {{ search?: string, category?: string, barcode?: string, includeInactive?: boolean, limit?: number, cursor?: string }} [query]
   */
  async function listProducts(uid, query) {
    const merchantId = await merchantService.getMerchantId(uid);
    return productRepository.list(merchantId, query);
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
