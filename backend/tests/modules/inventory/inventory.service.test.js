import { describe, it, expect, vi } from 'vitest';
import { createInventoryService } from '../../../src/modules/inventory/inventory.service.js';

function createFakeProductRepository(overrides = {}) {
  return {
    create: vi.fn((merchantId, product) => Promise.resolve({ id: 'prod_1', ...product })),
    get: vi
      .fn()
      .mockResolvedValue({ id: 'prod_1', merchantId: 'sb_merchant_1', name: 'Wax', isActive: true }),
    update: vi.fn((merchantId, productId, patch) => Promise.resolve({ id: productId, ...patch })),
    list: vi.fn().mockResolvedValue({ items: [], nextCursor: null }),
    ...overrides,
  };
}

function createFakeStockRepository(overrides = {}) {
  return {
    get: vi.fn(),
    adjustQuantity: vi.fn().mockResolvedValue({ productId: 'prod_1', storeId: 'sb_store_1', quantity: 10 }),
    ...overrides,
  };
}

function createFakeMerchantService(overrides = {}) {
  return { getMerchantId: vi.fn().mockResolvedValue('sb_merchant_1'), ...overrides };
}

function createFakeStoreService(overrides = {}) {
  return { verifyStoreOwnership: vi.fn().mockResolvedValue(undefined), ...overrides };
}

function createFakeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

const VALID_PRODUCT = {
  name: 'Wax — Tropical',
  sku: 'WAX-TRP-01',
  unit: 'pcs',
  costPrice: 60,
  sellingPrice: 99,
  taxRate: 25,
};

describe('inventory.service', () => {
  describe('createProduct', () => {
    it('resolves the merchantId and creates the product', async () => {
      const merchantService = createFakeMerchantService();
      const productRepository = createFakeProductRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService,
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const product = await service.createProduct('uid_1', VALID_PRODUCT);

      expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
      expect(productRepository.create).toHaveBeenCalledWith(
        'sb_merchant_1',
        expect.objectContaining({ ...VALID_PRODUCT, merchantId: 'sb_merchant_1', isActive: true }),
      );
      expect(product.id).toBe('prod_1');
    });
  });

  describe('getProduct', () => {
    it('returns the product when it exists', async () => {
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(service.getProduct('uid_1', 'prod_1')).resolves.toMatchObject({ id: 'prod_1' });
    });

    it('throws NotFoundError for an unknown product', async () => {
      const productRepository = createFakeProductRepository({ get: vi.fn().mockResolvedValue(null) });
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(service.getProduct('uid_1', 'missing')).rejects.toMatchObject({
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
    });
  });

  describe('updateProduct', () => {
    it('updates an existing product', async () => {
      const productRepository = createFakeProductRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const updated = await service.updateProduct('uid_1', 'prod_1', { sellingPrice: 109 });

      expect(productRepository.update).toHaveBeenCalledWith(
        'sb_merchant_1',
        'prod_1',
        expect.objectContaining({ sellingPrice: 109 }),
      );
      expect(updated.sellingPrice).toBe(109);
    });

    it('throws NotFoundError for an unknown product', async () => {
      const productRepository = createFakeProductRepository({ get: vi.fn().mockResolvedValue(null) });
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(service.updateProduct('uid_1', 'missing', { sellingPrice: 1 })).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });
  });

  describe('softDeleteProduct', () => {
    it('sets isActive to false rather than removing the record', async () => {
      const productRepository = createFakeProductRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const result = await service.softDeleteProduct('uid_1', 'prod_1');

      expect(productRepository.update).toHaveBeenCalledWith(
        'sb_merchant_1',
        'prod_1',
        expect.objectContaining({ isActive: false }),
      );
      expect(result.isActive).toBe(false);
    });
  });

  describe('listProducts', () => {
    it('delegates search/filter/pagination to the repository', async () => {
      const productRepository = createFakeProductRepository({
        list: vi.fn().mockResolvedValue({ items: [{ id: 'prod_1' }], nextCursor: 'prod_1' }),
      });
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const result = await service.listProducts('uid_1', { search: 'wax', limit: 10 });

      expect(productRepository.list).toHaveBeenCalledWith('sb_merchant_1', { search: 'wax', limit: 10 });
      expect(result).toEqual({ items: [{ id: 'prod_1' }], nextCursor: 'prod_1' });
    });
  });

  describe('adjustStock', () => {
    it('verifies product + store ownership and adjusts quantity', async () => {
      const storeService = createFakeStoreService();
      const stockRepository = createFakeStockRepository();
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService,
        logger: createFakeLogger(),
      });

      const result = await service.adjustStock('uid_1', 'prod_1', {
        storeId: 'sb_store_1',
        quantityDelta: 5,
        reason: 'restock',
      });

      expect(storeService.verifyStoreOwnership).toHaveBeenCalledWith('uid_1', 'sb_store_1');
      expect(stockRepository.adjustQuantity).toHaveBeenCalledWith('sb_store_1', 'prod_1', 5, 'uid_1');
      expect(result.quantity).toBe(10);
    });

    it('throws NotFoundError for an unknown product before touching stock', async () => {
      const productRepository = createFakeProductRepository({ get: vi.fn().mockResolvedValue(null) });
      const stockRepository = createFakeStockRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(
        service.adjustStock('uid_1', 'missing', { storeId: 'sb_store_1', quantityDelta: 5 }),
      ).rejects.toMatchObject({ name: 'NotFoundError' });
      expect(stockRepository.adjustQuantity).not.toHaveBeenCalled();
    });

    it('throws NotFoundError when the caller does not own the storeId', async () => {
      const notFound = Object.assign(new Error('not owned'), { name: 'NotFoundError', code: 'NOT_FOUND' });
      const storeService = createFakeStoreService({
        verifyStoreOwnership: vi.fn().mockRejectedValue(notFound),
      });
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService,
        logger: createFakeLogger(),
      });

      await expect(
        service.adjustStock('uid_1', 'prod_1', { storeId: 'not-mine', quantityDelta: 5 }),
      ).rejects.toBe(notFound);
    });

    it('throws InsufficientStockError when the repository aborts the transaction', async () => {
      const stockRepository = createFakeStockRepository({ adjustQuantity: vi.fn().mockResolvedValue(null) });
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(
        service.adjustStock('uid_1', 'prod_1', { storeId: 'sb_store_1', quantityDelta: -100 }),
      ).rejects.toMatchObject({ name: 'InsufficientStockError', code: 'INSUFFICIENT_STOCK' });
    });
  });
});
