import { describe, it, expect } from 'vitest';
import { createPaymentRepository } from '../../../src/modules/payments/payment.repository.js';

function createFakeDb() {
  const store = new Map();
  return {
    ref(path) {
      return {
        async set(value) {
          store.set(path, value);
        },
        async once() {
          return { val: () => store.get(path) ?? null };
        },
      };
    },
  };
}

describe('payment.repository', () => {
  it('getTerminalId() returns null when nothing has been registered for this store', async () => {
    const repository = createPaymentRepository({ getDb: () => createFakeDb() });

    await expect(repository.getTerminalId('sb_store_1')).resolves.toBeNull();
  });

  it('setTerminalId() persists the terminalId and getTerminalId() reads it back', async () => {
    const fakeDb = createFakeDb();
    const repository = createPaymentRepository({ getDb: () => fakeDb });

    await repository.setTerminalId('sb_store_1', 'term_1');

    await expect(repository.getTerminalId('sb_store_1')).resolves.toBe('term_1');
  });

  it('scopes cached terminals to the given storeId', async () => {
    const fakeDb = createFakeDb();
    const repository = createPaymentRepository({ getDb: () => fakeDb });

    await repository.setTerminalId('sb_store_1', 'term_1');

    await expect(repository.getTerminalId('sb_store_2')).resolves.toBeNull();
  });
});
