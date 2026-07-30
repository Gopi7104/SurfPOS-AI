import { describe, it, expect, vi } from 'vitest';
import { createStoreService } from '../../../src/modules/store/store.service.js';

function createFakeStoreClient(overrides = {}) {
  return { createStore: vi.fn(), getStore: vi.fn(), updateStore: vi.fn(), ...overrides };
}

function createFakeMapper(overrides = {}) {
  return {
    toWire: vi.fn((domain) => ({ merchant_id: domain.merchantId, name: domain.name })),
    toDomain: vi.fn((raw) => ({
      id: raw.store_id ?? null,
      merchantId: raw.merchant_id ?? null,
      name: raw.name ?? null,
      address: raw.address ?? null,
      capabilities: raw.capabilities ?? null,
      status: raw.status ?? null,
    })),
    toUpdateWire: vi.fn((domain) => ({ name: domain.name })),
    ...overrides,
  };
}

function createFakeStoreRepository(overrides = {}) {
  return {
    addReference: vi.fn().mockResolvedValue(undefined),
    hasReference: vi.fn().mockResolvedValue(true),
    listReferences: vi.fn().mockResolvedValue([]),
    ...overrides,
  };
}

function createFakeMerchantService(overrides = {}) {
  return { getMerchantId: vi.fn().mockResolvedValue('sb_merchant_1'), ...overrides };
}

function createFakeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

const VALID_INPUT = { name: 'Main Store', address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' } };

describe('store.service', () => {
  describe('createStore', () => {
    it('resolves the merchantId, creates the store via Surfboard, and registers a local reference', async () => {
      const storeClient = createFakeStoreClient({
        createStore: vi
          .fn()
          .mockResolvedValue({ store_id: 'sb_store_1', merchant_id: 'sb_merchant_1', name: 'Main Store' }),
      });
      const merchantService = createFakeMerchantService();
      const storeRepository = createFakeStoreRepository();
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository,
        merchantService,
        logger: createFakeLogger(),
      });

      const store = await service.createStore('uid_1', VALID_INPUT);

      expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
      expect(storeClient.createStore).toHaveBeenCalledWith({
        merchant_id: 'sb_merchant_1',
        name: 'Main Store',
      });
      expect(store).toMatchObject({ id: 'sb_store_1', merchantId: 'sb_merchant_1', name: 'Main Store' });
      expect(storeRepository.addReference).toHaveBeenCalledWith('uid_1', 'sb_store_1', {
        merchantId: 'sb_merchant_1',
      });
    });

    it('propagates a NotFoundError when the caller has no merchant reference yet', async () => {
      const notFound = Object.assign(new Error('no merchant'), { name: 'NotFoundError', code: 'NOT_FOUND' });
      const merchantService = createFakeMerchantService({
        getMerchantId: vi.fn().mockRejectedValue(notFound),
      });
      const service = createStoreService({
        storeClient: createFakeStoreClient(),
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository(),
        merchantService,
        logger: createFakeLogger(),
      });

      await expect(service.createStore('uid_1', VALID_INPUT)).rejects.toBe(notFound);
    });

    it('propagates a SurfboardApiError from the SDK untouched', async () => {
      const surfboardError = Object.assign(new Error('failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const storeClient = createFakeStoreClient({ createStore: vi.fn().mockRejectedValue(surfboardError) });
      const storeRepository = createFakeStoreRepository();
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository,
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.createStore('uid_1', VALID_INPUT)).rejects.toBe(surfboardError);
      expect(storeRepository.addReference).not.toHaveBeenCalled();
    });
  });

  describe('getStore', () => {
    it('returns the live store when the caller owns it', async () => {
      const storeClient = createFakeStoreClient({
        getStore: vi.fn().mockResolvedValue({ store_id: 'sb_store_1', name: 'Main Store' }),
      });
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository({ hasReference: vi.fn().mockResolvedValue(true) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.getStore('uid_1', 'sb_store_1')).resolves.toMatchObject({ id: 'sb_store_1' });
      expect(storeClient.getStore).toHaveBeenCalledWith('sb_store_1');
    });

    it('throws NotFoundError when the caller does not own the storeId', async () => {
      const storeClient = createFakeStoreClient();
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository({ hasReference: vi.fn().mockResolvedValue(false) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.getStore('uid_1', 'not-mine')).rejects.toMatchObject({
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
      expect(storeClient.getStore).not.toHaveBeenCalled();
    });
  });

  describe('updateStore', () => {
    it('maps the patch to wire format and calls updateStore when the caller owns it', async () => {
      const storeClient = createFakeStoreClient({
        updateStore: vi.fn().mockResolvedValue({ store_id: 'sb_store_1', name: 'New Name' }),
      });
      const mapper = createFakeMapper();
      const service = createStoreService({
        storeClient,
        mapper,
        storeRepository: createFakeStoreRepository({ hasReference: vi.fn().mockResolvedValue(true) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      const store = await service.updateStore('uid_1', 'sb_store_1', { name: 'New Name' });

      expect(mapper.toUpdateWire).toHaveBeenCalledWith({ name: 'New Name' });
      expect(storeClient.updateStore).toHaveBeenCalledWith('sb_store_1', { name: 'New Name' });
      expect(store.name).toBe('New Name');
    });

    it('throws NotFoundError when the caller does not own the storeId', async () => {
      const storeClient = createFakeStoreClient();
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository({ hasReference: vi.fn().mockResolvedValue(false) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.updateStore('uid_1', 'not-mine', { name: 'X' })).rejects.toMatchObject({
        name: 'NotFoundError',
      });
      expect(storeClient.updateStore).not.toHaveBeenCalled();
    });

    it('propagates a SurfboardApiError from the SDK untouched', async () => {
      const surfboardError = Object.assign(new Error('failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const storeClient = createFakeStoreClient({ updateStore: vi.fn().mockRejectedValue(surfboardError) });
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository({ hasReference: vi.fn().mockResolvedValue(true) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.updateStore('uid_1', 'sb_store_1', { name: 'X' })).rejects.toBe(surfboardError);
    });
  });

  describe('listStores', () => {
    it('hydrates each registered storeId with a live Surfboard fetch', async () => {
      const storeClient = createFakeStoreClient({
        getStore: vi
          .fn()
          .mockResolvedValueOnce({ store_id: 'sb_store_1', name: 'Store One' })
          .mockResolvedValueOnce({ store_id: 'sb_store_2', name: 'Store Two' }),
      });
      const storeRepository = createFakeStoreRepository({
        listReferences: vi.fn().mockResolvedValue(['sb_store_1', 'sb_store_2']),
      });
      const service = createStoreService({
        storeClient,
        mapper: createFakeMapper(),
        storeRepository,
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      const stores = await service.listStores('uid_1');

      expect(stores).toHaveLength(2);
      expect(stores.map((s) => s.id)).toEqual(['sb_store_1', 'sb_store_2']);
    });

    it('returns an empty array when the caller has no stores registered', async () => {
      const service = createStoreService({
        storeClient: createFakeStoreClient(),
        mapper: createFakeMapper(),
        storeRepository: createFakeStoreRepository({ listReferences: vi.fn().mockResolvedValue([]) }),
        merchantService: createFakeMerchantService(),
        logger: createFakeLogger(),
      });

      await expect(service.listStores('uid_1')).resolves.toEqual([]);
    });
  });
});
