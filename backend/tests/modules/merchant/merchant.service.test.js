import { describe, it, expect, vi } from 'vitest';
import { createMerchantService } from '../../../src/modules/merchant/merchant.service.js';

function createFakeMerchantClient(overrides = {}) {
  return { getMerchant: vi.fn(), updateMerchant: vi.fn(), getApplicationStatus: vi.fn(), ...overrides };
}

function createFakeMapper(overrides = {}) {
  return {
    toMerchantProfile: vi.fn((raw) => ({
      id: raw.data?.merchantId ?? null,
      name: raw.data?.merchantName ?? null,
      companyId: raw.data?.companyId ?? null,
      email: raw.data?.email ?? null,
      phoneNumber: raw.data?.phoneNumber ?? null,
      logoUrl: raw.data?.merchantLogoUrl ?? null,
      mccCode: raw.data?.mccCode !== null ? String(raw.data.mccCode) : null,
      countryCode: raw.data?.countryCode ?? null,
      address: raw.data?.address ?? null,
    })),
    toMerchantUpdateWire: vi.fn((domain) => ({ email: domain.email })),
    toApplicationStatusDomain: vi.fn((raw) => ({
      applicationId: raw.data?.applicationId ?? null,
      applicationStatus: raw.data?.applicationStatus ?? null,
      merchantId: raw.data?.merchantId ?? null,
      storeId: raw.data?.storeId ?? null,
      applicationUrl: raw.data?.webKybUrl ?? null,
      onlineOnboardingStatus: raw.data?.onlineOnboardingStatus ?? null,
    })),
    ...overrides,
  };
}

function createFakeMerchantRepository(overrides = {}) {
  return {
    getMerchantReference: vi.fn().mockResolvedValue({
      merchantId: 'sb_merchant_1',
      applicationId: 'app_1',
      applicationStatus: 'MERCHANT_CREATED',
    }),
    cacheMerchantMetadata: vi.fn().mockResolvedValue(undefined),
    ...overrides,
  };
}

function createFakeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

describe('merchant.service', () => {
  describe('getMerchantDetails', () => {
    it('resolves the merchantId and fetches the live profile', async () => {
      const merchantClient = createFakeMerchantClient({
        getMerchant: vi.fn().mockResolvedValue({
          status: 'SUCCESS',
          data: { merchantId: 'sb_merchant_1', merchantName: 'Blue Wave' },
        }),
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
      expect(merchant).toMatchObject({ id: 'sb_merchant_1', name: 'Blue Wave' });
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
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository: createFakeMerchantRepository(),
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantDetails('uid_1')).rejects.toBe(surfboardError);
    });
  });

  describe('updateMerchantDetails', () => {
    it('maps the patch to wire format, writes it, then re-fetches the fresh profile', async () => {
      const merchantClient = createFakeMerchantClient({
        updateMerchant: vi
          .fn()
          .mockResolvedValue({ status: 'SUCCESS', message: 'Successfully updated the merchant details.' }),
        getMerchant: vi.fn().mockResolvedValue({
          status: 'SUCCESS',
          data: { merchantId: 'sb_merchant_1', email: 'new@example.com' },
        }),
      });
      const mapper = createFakeMapper();
      const merchantRepository = createFakeMerchantRepository();
      const service = createMerchantService({
        merchantClient,
        mapper,
        merchantRepository,
        logger: createFakeLogger(),
      });

      const merchant = await service.updateMerchantDetails('uid_1', { email: 'new@example.com' });

      expect(mapper.toMerchantUpdateWire).toHaveBeenCalledWith({ email: 'new@example.com' });
      expect(merchantClient.updateMerchant).toHaveBeenCalledWith('sb_merchant_1', {
        email: 'new@example.com',
      });
      expect(merchantClient.getMerchant).toHaveBeenCalledWith('sb_merchant_1');
      expect(merchant.email).toBe('new@example.com');
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

      await expect(service.updateMerchantDetails('uid_1', { email: 'x@example.com' })).rejects.toMatchObject({
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

      await expect(service.updateMerchantDetails('uid_1', { email: 'x@example.com' })).rejects.toBe(
        surfboardError,
      );
    });
  });

  describe('getMerchantStatus', () => {
    it('polls the real Check Application Status endpoint and returns a normalized { merchantId, status } view', async () => {
      const merchantClient = createFakeMerchantClient({
        getApplicationStatus: vi.fn().mockResolvedValue({
          status: 'SUCCESS',
          data: {
            applicationId: 'app_1',
            applicationStatus: 'MERCHANT_CREATED',
            merchantId: 'sb_merchant_1',
          },
        }),
      });
      const merchantRepository = createFakeMerchantRepository();
      const service = createMerchantService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantRepository,
        logger: createFakeLogger(),
      });

      await expect(service.getMerchantStatus('uid_1')).resolves.toEqual({
        merchantId: 'sb_merchant_1',
        status: 'MERCHANT_CREATED',
      });
      expect(merchantClient.getApplicationStatus).toHaveBeenCalledWith('app_1');
      expect(merchantRepository.cacheMerchantMetadata).toHaveBeenCalledWith('uid_1', {
        applicationStatus: 'MERCHANT_CREATED',
        merchantId: 'sb_merchant_1',
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

    it('throws NotFoundError when the reference has no applicationId to poll', async () => {
      const merchantRepository = createFakeMerchantRepository({
        getMerchantReference: vi.fn().mockResolvedValue({ merchantId: 'sb_merchant_1', applicationId: null }),
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
