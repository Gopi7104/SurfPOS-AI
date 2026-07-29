import { describe, it, expect, vi } from 'vitest';
import { createMerchantService } from '../../../src/modules/merchant/merchant.service.js';

function createFakeMerchantClient(overrides = {}) {
  return { getMerchant: vi.fn(), updateMerchant: vi.fn(), ...overrides };
}

function createFakeMapper(overrides = {}) {
  return {
    toMerchantProfile: vi.fn((raw) => ({
      id: raw.merchant_id ?? null,
      businessName: raw.business_name ?? null,
      businessType: raw.business_type ?? null,
      contactEmail: raw.contact_email ?? null,
      contactPhone: raw.contact_phone ?? null,
      address: raw.address ?? null,
      status: raw.status ?? null,
    })),
    toMerchantUpdateWire: vi.fn((domain) => ({ business_name: domain.businessName })),
    ...overrides,
  };
}

function createFakeMerchantRepository(overrides = {}) {
  return {
    getMerchantReference: vi
      .fn()
      .mockResolvedValue({ merchantId: 'sb_merchant_1', applicationStatus: 'active' }),
    cacheMerchantMetadata: vi.fn().mockResolvedValue(undefined),
    ...overrides,
  };
}

function createFakeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

describe('merchant.service', () => {
  describe('getMerchantDetails', () => {
    it('resolves the merchantId, fetches the live profile, and refreshes the cached status', async () => {
      const merchantClient = createFakeMerchantClient({
        getMerchant: vi
          .fn()
          .mockResolvedValue({ merchant_id: 'sb_merchant_1', business_name: 'Blue Wave', status: 'active' }),
      });
      const merchantRepository = createFakeMerchantRepository();
      const logger = createFakeLogger();
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository,
        logger,
      });

      const merchant = await service.getMerchantDetails('uid_1');

      expect(merchantClient.getMerchant).toHaveBeenCalledWith('sb_merchant_1');
      expect(merchant).toMatchObject({ id: 'sb_merchant_1', businessName: 'Blue Wave', status: 'active' });
      expect(merchantRepository.cacheMerchantMetadata).toHaveBeenCalledWith('uid_1', {
        applicationStatus: 'active',
      });
      expect(logger.info).toHaveBeenCalled();
    });

    it('throws NotFoundError when the caller has no merchant reference yet', async () => {
      const merchantRepository = createFakeMerchantRepository({
        getMerchantReference: vi.fn().mockResolvedValue(null),
      });
      const service = createMerchantService({
        merchantClient: createFakeMerchantClient(),
        mapper: createFakeMapper(),
        merchantRepository,
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantDetails('uid_1')).rejects.toMatchObject({
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
    });

    it('propagates a SurfboardApiError from the SDK untouched', async () => {
      const surfboardError = Object.assign(new Error('Surfboard request failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const merchantClient = createFakeMerchantClient({
        getMerchant: vi.fn().mockRejectedValue(surfboardError),
      });
      const merchantRepository = createFakeMerchantRepository();
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository,
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantDetails('uid_1')).rejects.toBe(surfboardError);
      expect(merchantRepository.cacheMerchantMetadata).not.toHaveBeenCalled();
    });
  });

  describe('updateMerchantDetails', () => {
    it('maps the patch to wire format, calls updateMerchant, and refreshes the cache', async () => {
      const merchantClient = createFakeMerchantClient({
        updateMerchant: vi
          .fn()
          .mockResolvedValue({ merchant_id: 'sb_merchant_1', business_name: 'New Name', status: 'active' }),
      });
      const mapper = createFakeMapper();
      const merchantRepository = createFakeMerchantRepository();
      const service = createMerchantService({
        merchantClient,
        mapper,
        merchantRepository,
        logger: createFakeLogger(),
      });

      const merchant = await service.updateMerchantDetails('uid_1', { businessName: 'New Name' });

      expect(mapper.toMerchantUpdateWire).toHaveBeenCalledWith({ businessName: 'New Name' });
      expect(merchantClient.updateMerchant).toHaveBeenCalledWith('sb_merchant_1', {
        business_name: 'New Name',
      });
      expect(merchant.businessName).toBe('New Name');
      expect(merchantRepository.cacheMerchantMetadata).toHaveBeenCalledWith('uid_1', {
        applicationStatus: 'active',
      });
    });

    it('throws NotFoundError when the caller has no merchant reference yet', async () => {
      const merchantRepository = createFakeMerchantRepository({
        getMerchantReference: vi.fn().mockResolvedValue(null),
      });
      const service = createMerchantService({
        merchantClient: createFakeMerchantClient(),
        mapper: createFakeMapper(),
        merchantRepository,
        logger: createFakeLogger(),
      });

      await expect(service.updateMerchantDetails('uid_1', { businessName: 'X' })).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });

    it('propagates a SurfboardApiError from the SDK untouched', async () => {
      const surfboardError = Object.assign(new Error('Surfboard request failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const merchantClient = createFakeMerchantClient({
        updateMerchant: vi.fn().mockRejectedValue(surfboardError),
      });
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository: createFakeMerchantRepository(),
        logger: createFakeLogger(),
      });

      await expect(service.updateMerchantDetails('uid_1', { businessName: 'X' })).rejects.toBe(
        surfboardError,
      );
    });
  });

  describe('getMerchantStatus', () => {
    it('returns a normalized { merchantId, status } view', async () => {
      const merchantClient = createFakeMerchantClient({
        getMerchant: vi
          .fn()
          .mockResolvedValue({ merchant_id: 'sb_merchant_1', status: 'pending_verification' }),
      });
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository: createFakeMerchantRepository(),
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantStatus('uid_1')).resolves.toEqual({
        merchantId: 'sb_merchant_1',
        status: 'pending_verification',
      });
    });

    it('throws NotFoundError when the caller has no merchant reference yet', async () => {
      const merchantRepository = createFakeMerchantRepository({
        getMerchantReference: vi.fn().mockResolvedValue(null),
      });
      const service = createMerchantService({
        merchantClient: createFakeMerchantClient(),
        mapper: createFakeMapper(),
        merchantRepository,
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantStatus('uid_1')).rejects.toMatchObject({ name: 'NotFoundError' });
    });
  });
});
