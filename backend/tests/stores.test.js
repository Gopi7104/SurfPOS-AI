import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// Same rationale as tests/merchant.test.js: no Firebase project is provisioned in this
// environment, so these route-level tests exercise real validation/auth-middleware wiring; full
// business-logic coverage lives in tests/modules/store/store.service.test.js against
// constructor-injected fakes.

const VALID_STORE = { name: 'Main Store', address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' } };

describe('POST /stores', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).post('/stores').send(VALID_STORE);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /stores', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/stores');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /stores/:storeId', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/stores/sb_store_1');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('PATCH /stores/:storeId', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).patch('/stores/sb_store_1').send({ name: 'New Name' });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});
