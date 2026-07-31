import { describe, it, expect, vi } from 'vitest';
import { createInventoryService } from '../../../src/modules/inventory/inventory.service.js';
import { createProductRepository } from '../../../src/modules/inventory/product.repository.js';

function createFakeProductRepository(overrides = {}) {
  return {
    create: vi.fn((merchantId, product) => Promise.resolve({ id: 'prod_1', ...product })),
    get: vi
      .fn()
      .mockResolvedValue({ id: 'prod_1', merchantId: 'sb_merchant_1', name: 'Wax', isActive: true }),
    update: vi.fn((merchantId, productId, patch) => Promise.resolve({ id: productId, ...patch })),
    list: vi.fn().mockResolvedValue({ items: [], nextCursor: null }),
    listAll: vi.fn().mockResolvedValue([]),
    findBySku: vi.fn().mockResolvedValue(null),
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
  return {
    verifyStoreOwnership: vi.fn().mockResolvedValue(undefined),
    getPrimaryStoreId: vi.fn().mockResolvedValue(null),
    ...overrides,
  };
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

// Minimal in-memory stand-in for the Firebase Admin RTDB API surface product.repository.js uses —
// same shape as tests/modules/inventory/product.repository.test.js's fake — used here specifically
// to prove merchant isolation with a *real* repository (a fully-mocked repository couldn't tell us
// whether two merchantIds actually get separate storage paths).
function createFakeDb() {
  const store = new Map();
  let counter = 0;

  function makeRef(path) {
    return {
      async set(value) {
        store.set(path, value);
      },
      async update(patch) {
        store.set(path, { ...(store.get(path) || {}), ...patch });
      },
      async once() {
        if (store.has(path)) {
          return { val: () => store.get(path) };
        }
        const prefix = `${path}/`;
        const children = {};
        for (const [childPath, value] of store.entries()) {
          if (childPath.startsWith(prefix)) {
            children[childPath.slice(prefix.length)] = value;
          }
        }
        return { val: () => (Object.keys(children).length > 0 ? children : null) };
      },
      push() {
        counter += 1;
        const key = `prod_${counter}`;
        return { key, ...makeRef(`${path}/${key}`) };
      },
    };
  }

  return { ref: makeRef };
}

describe('inventory.service', () => {
  describe('merchant isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () => {
    it("never lets Merchant B see or fetch Merchant A's products, even by guessing the id", async () => {
      const fakeDb = createFakeDb();
      const productRepository = createProductRepository({ getDb: () => fakeDb });
      const merchantService = {
        getMerchantId: vi.fn((uid) =>
          Promise.resolve(uid === 'uid-merchant-a' ? 'sb_merchant_a' : 'sb_merchant_b'),
        ),
      };
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService,
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const productA = await service.createProduct('uid-merchant-a', VALID_PRODUCT);
      await service.createProduct('uid-merchant-b', { ...VALID_PRODUCT, sku: 'DIFFERENT-SKU' });

      const merchantBList = await service.listProducts('uid-merchant-b', {});
      expect(merchantBList.items.map((p) => p.id)).not.toContain(productA.id);
      expect(merchantBList.items).toHaveLength(1);

      await expect(service.getProduct('uid-merchant-b', productA.id)).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });

    it('lets two different merchants use the exact same SKU without conflicting', async () => {
      const fakeDb = createFakeDb();
      const productRepository = createProductRepository({ getDb: () => fakeDb });
      const merchantService = {
        getMerchantId: vi.fn((uid) =>
          Promise.resolve(uid === 'uid-merchant-a' ? 'sb_merchant_a' : 'sb_merchant_b'),
        ),
      };
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService,
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await service.createProduct('uid-merchant-a', VALID_PRODUCT);

      await expect(service.createProduct('uid-merchant-b', VALID_PRODUCT)).resolves.toMatchObject({
        sku: VALID_PRODUCT.sku,
      });
    });
  });

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

    it('defaults status to ACTIVE and discountPercentage to 0 when not provided', async () => {
      const productRepository = createFakeProductRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await service.createProduct('uid_1', VALID_PRODUCT);

      expect(productRepository.create).toHaveBeenCalledWith(
        'sb_merchant_1',
        expect.objectContaining({ status: 'ACTIVE', discountPercentage: 0 }),
      );
    });

    it('throws ConflictError when another active product already uses this SKU', async () => {
      const productRepository = createFakeProductRepository({
        findBySku: vi.fn().mockResolvedValue({ id: 'prod_existing', sku: VALID_PRODUCT.sku }),
      });
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(service.createProduct('uid_1', VALID_PRODUCT)).rejects.toMatchObject({
        name: 'ConflictError',
        code: 'CONFLICT',
      });
      expect(productRepository.create).not.toHaveBeenCalled();
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

    it('hydrates stockQuantity from the resolved store', async () => {
      const stockRepository = createFakeStockRepository({
        get: vi.fn().mockResolvedValue({ quantity: 42 }),
      });
      const storeService = createFakeStoreService({
        getPrimaryStoreId: vi.fn().mockResolvedValue('sb_store_1'),
      });
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService,
        logger: createFakeLogger(),
      });

      const product = await service.getProduct('uid_1', 'prod_1');

      expect(stockRepository.get).toHaveBeenCalledWith('sb_store_1', 'prod_1');
      expect(product.stockQuantity).toBe(42);
    });

    it('uses the explicit storeId when given, verifying ownership first', async () => {
      const storeService = createFakeStoreService();
      const stockRepository = createFakeStockRepository({ get: vi.fn().mockResolvedValue({ quantity: 5 }) });
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService,
        logger: createFakeLogger(),
      });

      const product = await service.getProduct('uid_1', 'prod_1', { storeId: 'sb_store_2' });

      expect(storeService.verifyStoreOwnership).toHaveBeenCalledWith('uid_1', 'sb_store_2');
      expect(storeService.getPrimaryStoreId).not.toHaveBeenCalled();
      expect(stockRepository.get).toHaveBeenCalledWith('sb_store_2', 'prod_1');
      expect(product.stockQuantity).toBe(5);
    });

    it('reports stockQuantity 0 when the merchant has no store yet', async () => {
      const stockRepository = createFakeStockRepository();
      const service = createInventoryService({
        productRepository: createFakeProductRepository(),
        stockRepository,
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      const product = await service.getProduct('uid_1', 'prod_1');

      expect(stockRepository.get).not.toHaveBeenCalled();
      expect(product.stockQuantity).toBe(0);
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

    it('does not check SKU uniqueness when the patch has no sku field', async () => {
      const productRepository = createFakeProductRepository();
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await service.updateProduct('uid_1', 'prod_1', { sellingPrice: 109 });

      expect(productRepository.findBySku).not.toHaveBeenCalled();
    });

    it('throws ConflictError when changing sku to one another active product already uses', async () => {
      const productRepository = createFakeProductRepository({
        findBySku: vi.fn().mockResolvedValue({ id: 'prod_other', sku: 'TAKEN' }),
      });
      const service = createInventoryService({
        productRepository,
        stockRepository: createFakeStockRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        logger: createFakeLogger(),
      });

      await expect(service.updateProduct('uid_1', 'prod_1', { sku: 'TAKEN' })).rejects.toMatchObject({
        name: 'ConflictError',
      });
      expect(productRepository.findBySku).toHaveBeenCalledWith('sb_merchant_1', 'TAKEN', 'prod_1');
      expect(productRepository.update).not.toHaveBeenCalled();
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
      expect(result).toEqual({ items: [{ id: 'prod_1', stockQuantity: 0 }], nextCursor: 'prod_1' });
    });

    describe('stock-aware filtering/sorting', () => {
      function stockAwareFixture() {
        const catalog = [
          { id: 'prod_a', name: 'A', reorderLevel: 5 },
          { id: 'prod_b', name: 'B', reorderLevel: 5 },
          { id: 'prod_c', name: 'C', reorderLevel: 5 },
        ];
        const quantities = { prod_a: 0, prod_b: 3, prod_c: 50 }; // out / low / in-stock
        const productRepository = createFakeProductRepository({
          listAll: vi.fn().mockResolvedValue(catalog),
        });
        const stockRepository = createFakeStockRepository({
          get: vi.fn((storeId, productId) => Promise.resolve({ quantity: quantities[productId] })),
        });
        const storeService = createFakeStoreService({
          getPrimaryStoreId: vi.fn().mockResolvedValue('sb_store_1'),
        });
        const service = createInventoryService({
          productRepository,
          stockRepository,
          merchantService: createFakeMerchantService(),
          storeService,
          logger: createFakeLogger(),
        });
        return { service, productRepository };
      }

      it('reads the full catalog via listAll (not the paginated list) when a stock filter is used', async () => {
        const { service, productRepository } = stockAwareFixture();

        await service.listProducts('uid_1', { stockFilter: 'inStock' });

        expect(productRepository.listAll).toHaveBeenCalled();
        expect(productRepository.list).not.toHaveBeenCalled();
      });

      it('filters outOfStock/lowStock/inStock correctly', async () => {
        const outOfStock = stockAwareFixture();
        const outResult = await outOfStock.service.listProducts('uid_1', { stockFilter: 'outOfStock' });
        expect(outResult.items.map((p) => p.id)).toEqual(['prod_a']);

        const lowStock = stockAwareFixture();
        const lowResult = await lowStock.service.listProducts('uid_1', { stockFilter: 'lowStock' });
        expect(lowResult.items.map((p) => p.id)).toEqual(['prod_b']);

        const inStock = stockAwareFixture();
        const inResult = await inStock.service.listProducts('uid_1', { stockFilter: 'inStock' });
        expect(inResult.items.map((p) => p.id)).toEqual(['prod_b', 'prod_c']);
      });

      it('sorts by stock quantity ascending/descending', async () => {
        const ascending = stockAwareFixture();
        const asc = await ascending.service.listProducts('uid_1', { sortBy: 'stock', sortOrder: 'asc' });
        expect(asc.items.map((p) => p.id)).toEqual(['prod_a', 'prod_b', 'prod_c']);

        const descending = stockAwareFixture();
        const desc = await descending.service.listProducts('uid_1', { sortBy: 'stock', sortOrder: 'desc' });
        expect(desc.items.map((p) => p.id)).toEqual(['prod_c', 'prod_b', 'prod_a']);
      });

      it('paginates the stock-aware result with the same cursor semantics', async () => {
        const { service } = stockAwareFixture();

        const firstPage = await service.listProducts('uid_1', { stockFilter: 'inStock', limit: 1 });
        expect(firstPage.items.map((p) => p.id)).toEqual(['prod_b']);
        expect(firstPage.nextCursor).toBe('prod_b');

        const secondPage = await service.listProducts('uid_1', {
          stockFilter: 'inStock',
          limit: 1,
          cursor: firstPage.nextCursor,
        });
        expect(secondPage.items.map((p) => p.id)).toEqual(['prod_c']);
        expect(secondPage.nextCursor).toBeNull();
      });
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
