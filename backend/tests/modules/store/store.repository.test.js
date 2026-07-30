import { describe, it, expect } from 'vitest';
import { createStoreRepository } from '../../../src/modules/store/store.repository.js';

// Simulates RTDB's hierarchical reads: reading a parent path returns a nested object built from
// every child path stored beneath it, matching how `storeReferences/{uid}` (parent) sees every
// `storeReferences/{uid}/{storeId}` (child) written via addReference().
function createFakeDb() {
  const store = new Map();
  return {
    ref(path) {
      return {
        async set(value) {
          store.set(path, value);
        },
        async once() {
          if (store.has(path)) {
            return { val: () => store.get(path) };
          }
          const prefix = `${path}/`;
          const children = {};
          for (const [childPath, value] of store.entries()) {
            if (childPath.startsWith(prefix)) {
              const key = childPath.slice(prefix.length);
              children[key] = value;
            }
          }
          return { val: () => (Object.keys(children).length > 0 ? children : null) };
        },
      };
    },
  };
}

describe('store.repository', () => {
  it('hasReference() returns false when nothing has been registered', async () => {
    const repository = createStoreRepository({ getDb: () => createFakeDb() });

    await expect(repository.hasReference('uid_1', 'sb_store_1')).resolves.toBe(false);
  });

  it('addReference() persists a minimal reference and hasReference()/listReferences() see it', async () => {
    const fakeDb = createFakeDb();
    const repository = createStoreRepository({ getDb: () => fakeDb });

    await repository.addReference('uid_1', 'sb_store_1', { merchantId: 'sb_merchant_1' });

    await expect(repository.hasReference('uid_1', 'sb_store_1')).resolves.toBe(true);
    await expect(repository.listReferences('uid_1')).resolves.toEqual(['sb_store_1']);
  });

  it('scopes references to the given uid, never leaking across users', async () => {
    const fakeDb = createFakeDb();
    const repository = createStoreRepository({ getDb: () => fakeDb });

    await repository.addReference('uid_1', 'sb_store_1', { merchantId: 'sb_merchant_1' });

    await expect(repository.hasReference('uid_2', 'sb_store_1')).resolves.toBe(false);
    await expect(repository.listReferences('uid_2')).resolves.toEqual([]);
  });

  it('listReferences() returns an empty array for a uid with no stores', async () => {
    const repository = createStoreRepository({ getDb: () => createFakeDb() });

    await expect(repository.listReferences('uid_1')).resolves.toEqual([]);
  });
});
