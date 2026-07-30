import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// Same rationale as tests/stores.test.js: no Firebase project is provisioned in this environment,
// so these route-level tests exercise real validation/auth-middleware wiring; full business-logic
// coverage lives in tests/modules/inventory/inventory.service.test.js against
// constructor-injected fakes.

const VALID_PRODUCT = {
  name: 'Wax — Tropical',
  sku: 'WAX-TRP-01',
  unit: 'pcs',
  costPrice: 60,
  sellingPrice: 99,
  taxRate: 25,
};

describe('POST /inventory/products', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).post('/inventory/products').send(VALID_PRODUCT);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /inventory/products', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/inventory/products');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /inventory/products/:productId', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/inventory/products/prod_1');

    expect(response.status).toBe(401);
  });
});

describe('PATCH /inventory/products/:productId', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).patch('/inventory/products/prod_1').send({ sellingPrice: 109 });

    expect(response.status).toBe(401);
  });
});

describe('DELETE /inventory/products/:productId', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).delete('/inventory/products/prod_1');

    expect(response.status).toBe(401);
  });
});

describe('PATCH /inventory/products/:productId/stock', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app)
      .patch('/inventory/products/prod_1/stock')
      .send({ storeId: 'sb_store_1', quantityDelta: 5 });

    expect(response.status).toBe(401);
  });
});
