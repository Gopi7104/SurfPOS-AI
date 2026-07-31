import { describe, it, expect } from 'vitest';
import { createProductRepository } from '../../../src/modules/inventory/product.repository.js';

// Minimal in-memory stand-in for the Firebase Admin RTDB API surface product.repository.js uses:
// set/update/once (with parent-path reads returning a nested object of children) and push()
// (returning a ref whose .key is the generated id).
function createFakeDb() {
  const store = new Map();
  let counter = 0;

  function makeRef(path) {
    return {
      async set(value) {
        store.set(path, value);
      },
      async update(patch) {
        store.set(path, { ...(store.get(path) || {}), ...patch });
      },
      async once() {
        if (store.has(path)) {
          return { val: () => store.get(path) };
        }
        const prefix = `${path}/`;
        const children = {};
        for (const [childPath, value] of store.entries()) {
          if (childPath.startsWith(prefix)) {
            children[childPath.slice(prefix.length)] = value;
          }
        }
        return { val: () => (Object.keys(children).length > 0 ? children : null) };
      },
      push() {
        counter += 1;
        const key = `prod_${counter}`;
        return { key, ...makeRef(`${path}/${key}`) };
      },
    };
  }

  return { ref: makeRef };
}

function baseProduct(overrides = {}) {
  return {
    name: 'Wax — Tropical',
    sku: 'WAX-TRP-01',
    barcode: '8901234567890',
    category: 'Accessories',
    unit: 'pcs',
    costPrice: 60,
    sellingPrice: 99,
    taxRate: 25,
    isActive: true,
    createdAt: 1,
    updatedAt: 1,
    ...overrides,
  };
}

describe('product.repository', () => {
  it('create() generates an id and persists the product', async () => {
    const repository = createProductRepository({ getDb: () => createFakeDb() });
    const product = await repository.create('sb_merchant_1', baseProduct());

    expect(product.id).toBeTruthy();
    expect(product.name).toBe('Wax — Tropical');
  });

  it('get() returns null for an unknown product', async () => {
    const repository = createProductRepository({ getDb: () => createFakeDb() });

    await expect(repository.get('sb_merchant_1', 'missing')).resolves.toBeNull();
  });

  it('get()/update() round-trip a persisted product', async () => {
    const fakeDb = createFakeDb();
    const repository = createProductRepository({ getDb: () => fakeDb });
    const product = await repository.create('sb_merchant_1', baseProduct());

    const updated = await repository.update('sb_merchant_1', product.id, { sellingPrice: 109, updatedAt: 2 });

    expect(updated).toMatchObject({ id: product.id, sellingPrice: 109, updatedAt: 2 });
    await expect(repository.get('sb_merchant_1', product.id)).resolves.toMatchObject({ sellingPrice: 109 });
  });

  describe('list()', () => {
    it('returns only active products by default', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create('sb_merchant_1', baseProduct({ name: 'Active One', isActive: true }));
      await repository.create('sb_merchant_1', baseProduct({ name: 'Inactive One', isActive: false }));

      const { items } = await repository.list('sb_merchant_1');

      expect(items).toHaveLength(1);
      expect(items[0].name).toBe('Active One');
    });

    it('includes inactive products when includeInactive is true', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create('sb_merchant_1', baseProduct({ isActive: false }));

      const { items } = await repository.list('sb_merchant_1', { includeInactive: true });

      expect(items).toHaveLength(1);
    });

    it('filters by search term (case-insensitive substring of name)', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Wax — Tropical', sku: 'WAX-TRP-01', barcode: '111' }),
      );
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Leash — Coil', sku: 'LSH-COIL-01', barcode: '222' }),
      );

      const { items } = await repository.list('sb_merchant_1', { search: 'wax' });

      expect(items).toHaveLength(1);
      expect(items[0].name).toBe('Wax — Tropical');
    });

    it('search also matches SKU and barcode substrings, not just name', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Wax — Tropical', sku: 'WAX-TRP-01', barcode: '111' }),
      );
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Leash — Coil', sku: 'LSH-COIL-01', barcode: '222' }),
      );

      await expect(
        repository.list('sb_merchant_1', { search: 'lsh-coil' }).then((r) => r.items),
      ).resolves.toHaveLength(1);
      await expect(repository.list('sb_merchant_1', { search: '222' }).then((r) => r.items)).resolves.toEqual(
        [expect.objectContaining({ name: 'Leash — Coil' })],
      );
    });

    it('sorts by name, price, and updatedAt', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Zinc Block', sku: 'A', sellingPrice: 50, updatedAt: 3 }),
      );
      await repository.create(
        'sb_merchant_1',
        baseProduct({ name: 'Ankle Leash', sku: 'B', sellingPrice: 150, updatedAt: 1 }),
      );

      const byName = await repository.list('sb_merchant_1', { sortBy: 'name' });
      expect(byName.items.map((p) => p.name)).toEqual(['Ankle Leash', 'Zinc Block']);

      const byPriceDesc = await repository.list('sb_merchant_1', { sortBy: 'price', sortOrder: 'desc' });
      expect(byPriceDesc.items.map((p) => p.name)).toEqual(['Ankle Leash', 'Zinc Block']);

      const byUpdatedAtDesc = await repository.list('sb_merchant_1', {
        sortBy: 'updatedAt',
        sortOrder: 'desc',
      });
      expect(byUpdatedAtDesc.items.map((p) => p.name)).toEqual(['Zinc Block', 'Ankle Leash']);
    });

    it('filters by category and barcode', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create('sb_merchant_1', baseProduct({ category: 'Accessories', barcode: '111' }));
      await repository.create('sb_merchant_1', baseProduct({ category: 'Boards', barcode: '222' }));

      await expect(
        repository.list('sb_merchant_1', { category: 'Boards' }).then((r) => r.items),
      ).resolves.toHaveLength(1);
      await expect(
        repository.list('sb_merchant_1', { barcode: '111' }).then((r) => r.items),
      ).resolves.toHaveLength(1);
    });

    it('paginates with limit + cursor', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      for (let i = 0; i < 5; i += 1) {
        await repository.create('sb_merchant_1', baseProduct({ name: `Product ${i}` }));
      }

      const firstPage = await repository.list('sb_merchant_1', { limit: 2 });
      expect(firstPage.items).toHaveLength(2);
      expect(firstPage.nextCursor).toBeTruthy();

      const secondPage = await repository.list('sb_merchant_1', { limit: 2, cursor: firstPage.nextCursor });
      expect(secondPage.items).toHaveLength(2);
      expect(secondPage.items[0].id).not.toBe(firstPage.items[0].id);

      const lastPage = await repository.list('sb_merchant_1', { limit: 2, cursor: secondPage.nextCursor });
      expect(lastPage.items).toHaveLength(1);
      expect(lastPage.nextCursor).toBeNull();
    });
  });

  describe('findBySku()', () => {
    it('finds an active product with a matching SKU for the merchant', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      const product = await repository.create('sb_merchant_1', baseProduct({ sku: 'UNIQUE-1' }));

      await expect(repository.findBySku('sb_merchant_1', 'UNIQUE-1')).resolves.toMatchObject({
        id: product.id,
      });
      await expect(repository.findBySku('sb_merchant_1', 'NOPE')).resolves.toBeNull();
    });

    it('ignores soft-deleted products, so their SKU can be reused', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      await repository.create('sb_merchant_1', baseProduct({ sku: 'REUSABLE', isActive: false }));

      await expect(repository.findBySku('sb_merchant_1', 'REUSABLE')).resolves.toBeNull();
    });

    it('excludes the given productId — a product keeping its own SKU on update is not a conflict', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      const product = await repository.create('sb_merchant_1', baseProduct({ sku: 'SELF-1' }));

      await expect(repository.findBySku('sb_merchant_1', 'SELF-1', product.id)).resolves.toBeNull();
    });
  });

  describe('listAll()', () => {
    it('returns every filtered+sorted product, unpaginated', async () => {
      const fakeDb = createFakeDb();
      const repository = createProductRepository({ getDb: () => fakeDb });
      for (let i = 0; i < 30; i += 1) {
        await repository.create('sb_merchant_1', baseProduct({ name: `Product ${i}`, sku: `SKU-${i}` }));
      }

      const all = await repository.listAll('sb_merchant_1');

      expect(all).toHaveLength(30);
    });
  });
});
