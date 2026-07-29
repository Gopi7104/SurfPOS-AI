import { describe, it, expect, vi } from 'vitest';
import { createMerchantApplicationService } from '../../../src/modules/merchant/merchantApplication.service.js';

function createFakeMerchantClient(overrides = {}) {
  return { createMerchant: vi.fn(), ...overrides };
}

function createFakeMapper(overrides = {}) {
  return {
    toWire: vi.fn((domain) => ({ business_name: domain.businessName })),
    toDomain: vi.fn((raw) => ({
      applicationId: raw.application_id ?? null,
      merchantId: raw.merchant_id ?? null,
      applicationStatus: raw.status ?? 'pending_verification',
      applicationUrl: raw.onboarding_url ?? null,
    })),
    ...overrides,
  };
}

function createFakeRepository(overrides = {}) {
  return {
    get: vi.fn().mockResolvedValue(null),
    create: vi.fn((uid, application) => Promise.resolve(application)),
    update: vi.fn(),
    ...overrides,
  };
}

const VALID_INPUT = {
  businessName: 'Blue Wave Surf Shop',
  businessType: 'retail',
  contactEmail: 'owner@example.com',
  contactPhone: '+46700000000',
  address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
};

describe('merchantApplication.service', () => {
  describe('submitApplication', () => {
    it('creates a Surfboard merchant application and persists the normalized tracking record', async () => {
      const merchantClient = createFakeMerchantClient({
        createMerchant: vi.fn().mockResolvedValue({
          application_id: 'app_1',
          status: 'pending_verification',
          onboarding_url: 'https://onboard.example.test/app_1',
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
      expect(merchantClient.createMerchant).toHaveBeenCalledWith({ business_name: 'Blue Wave Surf Shop' });
      expect(application).toMatchObject({
        applicationId: 'app_1',
        merchantId: null,
        applicationStatus: 'pending_verification',
        applicationUrl: 'https://onboard.example.test/app_1',
      });
      expect(typeof application.submittedAt).toBe('number');
      expect(merchantApplicationRepository.create).toHaveBeenCalledWith('uid_1', application);
    });

    it('falls back to uid as the applicationId when Surfboard omits one', async () => {
      const merchantClient = createFakeMerchantClient({
        createMerchant: vi.fn().mockResolvedValue({ status: 'pending_verification' }),
      });
      const mapper = createFakeMapper({
        toDomain: vi.fn(() => ({
          applicationId: null,
          merchantId: null,
          applicationStatus: 'pending_verification',
          applicationUrl: null,
        })),
      });
      const service = createMerchantApplicationService({
        merchantClient,
        mapper,
        merchantApplicationRepository: createFakeRepository(),
      });

      const application = await service.submitApplication('uid_1', VALID_INPUT);

      expect(application.applicationId).toBe('uid_1');
    });

    it('throws ConflictError when an application already exists for this uid', async () => {
      const merchantClient = createFakeMerchantClient();
      const merchantApplicationRepository = createFakeRepository({
        get: vi.fn().mockResolvedValue({ applicationId: 'uid_1', applicationStatus: 'pending_verification' }),
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
        get: vi.fn().mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'active' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.getApplication('uid_1', 'app_1')).resolves.toEqual({
        applicationId: 'app_1',
        applicationStatus: 'active',
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
        get: vi.fn().mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'active' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.getApplication('uid_1', 'someone-elses-app')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });
  });

  describe('listApplications', () => {
    it('returns a single-item array when an application exists', async () => {
      const merchantApplicationRepository = createFakeRepository({
        get: vi.fn().mockResolvedValue({ applicationId: 'app_1', applicationStatus: 'active' }),
      });
      const service = createMerchantApplicationService({ merchantApplicationRepository });

      await expect(service.listApplications('uid_1')).resolves.toEqual([
        { applicationId: 'app_1', applicationStatus: 'active' },
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
