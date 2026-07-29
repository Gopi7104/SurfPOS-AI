import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// Same rationale as tests/auth.test.js and tests/merchantApplications.test.js: no Firebase
// project is provisioned in this environment, so these route-level tests exercise real
// auth-middleware wiring; full business-logic coverage lives in
// tests/modules/merchant/merchant.service.test.js against constructor-injected fakes.

describe('GET /merchant', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/merchant');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('PATCH /merchant', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).patch('/merchant').send({ businessName: 'New Name' });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /merchant/status', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/merchant/status');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /merchant/applications (still reachable after mounting /merchant)', () => {
  it('is not shadowed by the new /merchant router and still requires auth', async () => {
    const response = await request(app).get('/merchant/applications');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});
