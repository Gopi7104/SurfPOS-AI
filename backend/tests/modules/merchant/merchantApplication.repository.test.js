import { describe, it, expect } from 'vitest';
import { createMerchantApplicationRepository } from '../../../src/modules/merchant/merchantApplication.repository.js';

function createFakeDb() {
  const store = new Map();
  return {
    ref(path) {
      return {
        async set(value) {
          store.set(path, value);
        },
        async update(patch) {
          store.set(path, { ...(store.get(path) || {}), ...patch });
        },
        async once() {
          return { val: () => store.get(path) ?? null };
        },
      };
    },
  };
}

describe('merchantApplication.repository', () => {
  it('get() returns null for an uid with no application', async () => {
    const repository = createMerchantApplicationRepository({ getDb: () => createFakeDb() });

    await expect(repository.get('uid_1')).resolves.toBeNull();
  });

  it('create() persists the application and get() returns it back', async () => {
    const fakeDb = createFakeDb();
    const repository = createMerchantApplicationRepository({ getDb: () => fakeDb });
    const application = {
      applicationId: 'uid_1',
      merchantId: null,
      applicationStatus: 'pending_verification',
      applicationUrl: 'https://onboard.example.test/uid_1',
      submittedAt: 1,
      updatedAt: 1,
    };

    await repository.create('uid_1', application);

    await expect(repository.get('uid_1')).resolves.toEqual(application);
  });

  it('update() merges a patch onto the existing record', async () => {
    const fakeDb = createFakeDb();
    const repository = createMerchantApplicationRepository({ getDb: () => fakeDb });
    await repository.create('uid_1', {
      applicationId: 'uid_1',
      merchantId: null,
      applicationStatus: 'pending_verification',
      applicationUrl: null,
      submittedAt: 1,
      updatedAt: 1,
    });

    const updated = await repository.update('uid_1', {
      merchantId: 'sb_merchant_1',
      applicationStatus: 'active',
      updatedAt: 2,
    });

    expect(updated).toMatchObject({
      applicationId: 'uid_1',
      merchantId: 'sb_merchant_1',
      applicationStatus: 'active',
      submittedAt: 1,
      updatedAt: 2,
    });
  });

  it('scopes reads/writes to the given uid, never touching another uid', async () => {
    const fakeDb = createFakeDb();
    const repository = createMerchantApplicationRepository({ getDb: () => fakeDb });

    await repository.create('uid_1', { applicationId: 'uid_1', applicationStatus: 'pending_verification' });

    await expect(repository.get('uid_2')).resolves.toBeNull();
  });
});
