import { describe, it, expect } from 'vitest';
import { createStockRepository } from '../../../src/modules/inventory/stock.repository.js';

// Minimal in-memory stand-in for Firebase Admin RTDB's transaction() contract: the update
// function receives the current value (or null), and returning undefined aborts the write.
function createFakeDb() {
  const store = new Map();
  return {
    ref(path) {
      return {
        async once() {
          return { val: () => store.get(path) ?? null };
        },
        async transaction(updateFn) {
          const current = store.get(path) ?? null;
          const result = updateFn(current);
          if (result === undefined) {
            return { committed: false, snapshot: { val: () => current } };
          }
          store.set(path, result);
          return { committed: true, snapshot: { val: () => result } };
        },
      };
    },
  };
}

describe('stock.repository', () => {
  it('get() returns null when no stock record exists', async () => {
    const repository = createStockRepository({ getDb: () => createFakeDb() });

    await expect(repository.get('sb_store_1', 'prod_1')).resolves.toBeNull();
  });

  describe('adjustQuantity()', () => {
    it('creates a new record on the first restock (positive delta) when none exists', async () => {
      const repository = createStockRepository({ getDb: () => createFakeDb() });

      const result = await repository.adjustQuantity('sb_store_1', 'prod_1', 10, 'uid_1');

      expect(result).toMatchObject({
        productId: 'prod_1',
        storeId: 'sb_store_1',
        quantity: 10,
        lastUpdatedBy: 'uid_1',
      });
      expect(typeof result.lastRestockedAt).toBe('number');
    });

    it('aborts (returns null) when deducting from a record that does not exist yet', async () => {
      const repository = createStockRepository({ getDb: () => createFakeDb() });

      await expect(repository.adjustQuantity('sb_store_1', 'prod_1', -5, 'uid_1')).resolves.toBeNull();
    });

    it('accumulates quantity across multiple positive adjustments', async () => {
      const fakeDb = createFakeDb();
      const repository = createStockRepository({ getDb: () => fakeDb });

      await repository.adjustQuantity('sb_store_1', 'prod_1', 10, 'uid_1');
      const result = await repository.adjustQuantity('sb_store_1', 'prod_1', 5, 'uid_1');

      expect(result.quantity).toBe(15);
    });

    it('deducts quantity when enough stock is available', async () => {
      const fakeDb = createFakeDb();
      const repository = createStockRepository({ getDb: () => fakeDb });

      await repository.adjustQuantity('sb_store_1', 'prod_1', 10, 'uid_1');
      const result = await repository.adjustQuantity('sb_store_1', 'prod_1', -4, 'uid_1');

      expect(result.quantity).toBe(6);
    });

    it('aborts (returns null) rather than letting quantity go negative', async () => {
      const fakeDb = createFakeDb();
      const repository = createStockRepository({ getDb: () => fakeDb });

      await repository.adjustQuantity('sb_store_1', 'prod_1', 3, 'uid_1');
      const result = await repository.adjustQuantity('sb_store_1', 'prod_1', -10, 'uid_1');

      expect(result).toBeNull();
      await expect(repository.get('sb_store_1', 'prod_1')).resolves.toMatchObject({ quantity: 3 });
    });

    it('only updates lastRestockedAt on a positive delta, not a negative one', async () => {
      const fakeDb = createFakeDb();
      const repository = createStockRepository({ getDb: () => fakeDb });

      const restocked = await repository.adjustQuantity('sb_store_1', 'prod_1', 10, 'uid_1');
      const deducted = await repository.adjustQuantity('sb_store_1', 'prod_1', -2, 'uid_1');

      expect(deducted.lastRestockedAt).toBe(restocked.lastRestockedAt);
    });
  });
});
