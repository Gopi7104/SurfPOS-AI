import { describe, it, expect, vi } from 'vitest';
import { createMerchantApplicationService } from '../../../src/modules/merchant/merchantApplication.service.js';

function createFakeMerchantClient(overrides = {}) {
  return { createMerchant: vi.fn(), getApplicationStatus: vi.fn(), ...overrides };
}

function createFakeMapper(overrides = {}) {
  return {
    toWire: vi.fn((domain) => ({ country: domain.country })),
    toDomain: vi.fn((raw) => ({
      applicationId: raw.data?.applicationId ?? null,
      merchantId: raw.data?.merchantId ?? null,
      storeId: raw.data?.storeId ?? null,
      applicationStatus: 'APPLICATION_INITIATED',
      applicationUrl: raw.data?.webKybUrl ?? null,
      shortLinkUrl: raw.data?.shortLinkUrl ?? null,
    })),
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

function createFakeRepository(overrides = {}) {
  return {
    get: vi.fn().mockResolvedValue(null),
    create: vi.fn((uid, application) => Promise.resolve(application)),
    update: vi.fn((uid, patch) => Promise.resolve(patch)),
    ...overrides,
  };
}

const VALID_INPUT = {
  country: 'SE',
  organisation: {
    corporateId: '1234567812',
    address: { addressLine1: 'Main Street 123', city: 'Stockholm', countryCode: 'SE', postalCode: '123 45' },
  },
  store: {
    name: 'Main Street Store',
    email: 'store@example.com',
    phoneNumber: { code: '46', number: '701234567' },
    address: { addressLine1: 'Main Street 123', city: 'Stockholm', countryCode: 'SE', postalCode: '123 45' },
  },
};

describe('merchantApplication.service', () => {
  describe('submitApplication', () => {
    it('creates a Surfboard merchant application and persists the normalized tracking record', async () => {
      const merchantClient = createFakeMerchantClient({
        createMerchant: vi.fn().mockResolvedValue({
          status: 'SUCCESS',
          data: { applicationId: 'app_1', webKybUrl: 'https://surfkyb.com/app_1' },
          message: 'ok',
        }),
      });
      const mapper = createFakeMapper();
      const merchantApplicationRepository = createFakeRepository();
      const service = createMerchantApplicationService({
        merchantClient,
        mapper,
        merchantApplicationRepository,
      });

      const application = await service.submitApplication('uid_1', VALID_INPUT);

      expect(mapper.toWire).toHaveBeenCalledWith(VALID_INPUT);
      expect(merchantClient.createMerchant).toHaveBeenCalledWith({ country: 'SE' });
      expect(application).toMatchObject({
        applicationId: 'app_1',
        merchantId: null,
        storeId: null,
        applicationStatus: 'APPLICATION_INITIATED',
        applicationUrl: 'https://surfkyb.com/app_1',
        shortLinkUrl: null,
      });
      expect(typeof application.submittedAt).toBe('number');
      expect(merchantApplicationRepository.create).toHaveBeenCalledWith('uid_1', application);
    });

    it('falls back to uid as the applicationId when Surfboard omits one', async () => {
      const merchantClient = createFakeMerchantClient({
        createMerchant: vi.fn().mockResolvedValue({ status: 'SUCCESS', data: {}, message: 'ok' }),
      });
      const service = createMerchantApplicationService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantApplicationRepository: createFakeRepository(),
      });

      const application = await service.submitApplication('uid_1', VALID_INPUT);

      expect(application.applicationId).toBe('uid_1');
    });

    it('throws ConflictError when an application already exists for this uid', async () => {
      const merchantClient = createFakeMerchantClient();
      const merchantApplicationRepository = createFakeRepository({
        get: vi
          .fn()
          .mockResolvedValue({ applicationId: 'uid_1', applicationStatus: 'APPLICATION_INITIATED' }),
      });
      const service = createMerchantApplicationService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantApplicationRepository,
      });

      await expect(service.submitApplication('uid_1', VALID_INPUT)).rejects.toMatchObject({
        name: 'ConflictError',
        code: 'CONFLICT',
      });
      expect(merchantClient.createMerchant).not.toHaveBeenCalled();
    });

    it('propagates a SurfboardApiError from the SDK untouched', async () => {
      const surfboardError = Object.assign(new Error('Surfboard request failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
        statusCode: 502,
      });
      const merchantClient = createFakeMerchantClient({
        createMerchant: vi.fn().mockRejectedValue(surfboardError),
      });
      const merchantApplicationRepository = createFakeRepository();
      const service = createMerchantApplicationService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantApplicationRepository,
      });

      await expect(service.submitApplication('uid_1', VALID_INPUT)).rejects.toBe(surfboardError);
      expect(merchantApplicationRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('getApplication', () => {
    it('returns the application when the id matches the caller’s own record', async () => {
      const merchantApplicationRepository = createFakeRepository({
        get: vi
          .fn()
          .mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'APPLICATION_SUBMITTED' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.getApplication('uid_1', 'app_1')).resolves.toEqual({
        applicationId: 'app_1',
        applicationStatus: 'APPLICATION_SUBMITTED',
      });
    });

    it('throws NotFoundError when the uid has no application', async () => {
      const service = createMerchantApplicationService({
        merchantApplicationRepository: createFakeRepository({ get: vi.fn().mockResolvedValue(null) }),
      });

      await expect(service.getApplication('uid_1', 'app_1')).rejects.toMatchObject({
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
    });

    it('throws NotFoundError when the requested id does not match the caller’s own application', async () => {
      const merchantApplicationRepository = createFakeRepository({
        get: vi
          .fn()
          .mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'APPLICATION_SUBMITTED' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.getApplication('uid_1', 'someone-elses-app')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });
  });

  describe('refreshApplicationStatus', () => {
    it('polls Surfboard and persists the refreshed status/merchantId/storeId', async () => {
      const merchantClient = createFakeMerchantClient({
        getApplicationStatus: vi.fn().mockResolvedValue({
          status: 'SUCCESS',
          data: {
            applicationId: 'app_1',
            applicationStatus: 'MERCHANT_CREATED',
            merchantId: 'm-1',
            storeId: 's-1',
          },
          message: 'ok',
        }),
      });
      const merchantApplicationRepository = createFakeRepository({
        get: vi.fn().mockResolvedValue({
          applicationId: 'app_1',
          applicationStatus: 'APPLICATION_SUBMITTED',
          merchantId: null,
          storeId: null,
        }),
      });
      const service = createMerchantApplicationService({
        merchantClient,
        mapper: createFakeMapper(),
        merchantApplicationRepository,
      });

      const application = await service.refreshApplicationStatus('uid_1', 'app_1');

      expect(merchantClient.getApplicationStatus).toHaveBeenCalledWith('app_1');
      expect(merchantApplicationRepository.update).toHaveBeenCalledWith('uid_1', {
        applicationStatus: 'MERCHANT_CREATED',
        merchantId: 'm-1',
        storeId: 's-1',
        applicationUrl: null,
      });
      expect(application).toMatchObject({
        applicationStatus: 'MERCHANT_CREATED',
        merchantId: 'm-1',
        storeId: 's-1',
      });
    });

    it('throws NotFoundError when the requested id does not match the caller’s own application', async () => {
      const merchantApplicationRepository = createFakeRepository({
        get: vi
          .fn()
          .mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'APPLICATION_INITIATED' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.refreshApplicationStatus('uid_1', 'someone-elses-app')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });
  });

  describe('listApplications', () => {
    it('returns a single-item array when an application exists', async () => {
      const merchantApplicationRepository = createFakeRepository({
        get: vi
          .fn()
          .mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'APPLICATION_SUBMITTED' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.listApplications('uid_1')).resolves.toEqual([
        { applicationId: 'app_1', applicationStatus: 'APPLICATION_SUBMITTED' },
      ]);
    });

    it('returns an empty array when no application exists', async () => {
      const service = createMerchantApplicationService({
        merchantApplicationRepository: createFakeRepository({ get: vi.fn().mockResolvedValue(null) }),
      });

      await expect(service.listApplications('uid_1')).resolves.toEqual([]);
    });
  });
});
