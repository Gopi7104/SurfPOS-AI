import { describe, it, expect, vi } from 'vitest';
import { createMerchantRepository } from '../../../src/modules/merchant/merchant.repository.js';

function createFakeMerchantApplicationRepository(overrides = {}) {
  return {
    get: vi.fn().mockResolvedValue(null),
    update: vi.fn((uid, patch) => Promise.resolve({ ...patch })),
    ...overrides,
  };
}

describe('merchant.repository', () => {
  describe('getMerchantReference', () => {
    it('returns null when no application exists', async () => {
      const merchantApplicationRepository = createFakeMerchantApplicationRepository();
      const repository = createMerchantRepository({ merchantApplicationRepository });

      await expect(repository.getMerchantReference('uid_1')).resolves.toBeNull();
    });

    it('returns null when an application exists but no merchantId has been assigned yet', async () => {
      const merchantApplicationRepository = createFakeMerchantApplicationRepository({
        get: vi.fn().mockResolvedValue({
          applicationId: 'uid_1',
          merchantId: null,
          applicationStatus: 'pending_verification',
        }),
      });
      const repository = createMerchantRepository({ merchantApplicationRepository });

      await expect(repository.getMerchantReference('uid_1')).resolves.toBeNull();
    });

    it('returns the merchantId + cached status when an application has one assigned', async () => {
      const merchantApplicationRepository = createFakeMerchantApplicationRepository({
        get: vi.fn().mockResolvedValue({
          applicationId: 'uid_1',
          merchantId: 'sb_merchant_1',
          applicationStatus: 'active',
        }),
      });
      const repository = createMerchantRepository({ merchantApplicationRepository });

      await expect(repository.getMerchantReference('uid_1')).resolves.toEqual({
        merchantId: 'sb_merchant_1',
        applicationId: 'uid_1',
        applicationStatus: 'active',
      });
    });
  });

  describe('cacheMerchantMetadata', () => {
    it('delegates to merchantApplicationRepository.update with an updatedAt stamp', async () => {
      const merchantApplicationRepository = createFakeMerchantApplicationRepository();
      const repository = createMerchantRepository({ merchantApplicationRepository });

      await repository.cacheMerchantMetadata('uid_1', { applicationStatus: 'active' });

      expect(merchantApplicationRepository.update).toHaveBeenCalledWith(
        'uid_1',
        expect.objectContaining({ applicationStatus: 'active', updatedAt: expect.any(Number) }),
      );
    });
  });
});
