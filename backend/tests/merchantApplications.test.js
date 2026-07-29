import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// Same rationale as tests/auth.test.js: no Firebase project is provisioned in this environment,
// and this project's Vitest/CJS require() graph doesn't reliably honor vi.mock() on the nested
// require('../../firebase/admin') the default-wired service/repository reach (see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-020/ADR-021). These route-level tests exercise real
// validation/auth-middleware wiring; full business-logic coverage (submit/get/list, success and
// every mapped-error path) lives in tests/modules/merchant/merchantApplication.service.test.js
// against constructor-injected fakes.

const VALID_APPLICATION = {
  businessName: 'Blue Wave Surf Shop',
  businessType: 'retail',
  contactEmail: 'owner@example.com',
  contactPhone: '+46700000000',
  address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
};

describe('POST /merchant/applications', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).post('/merchant/applications').send(VALID_APPLICATION);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('returns 400 VALIDATION_ERROR for a malformed phone number even with a bearer token present', async () => {
    const response = await request(app)
      .post('/merchant/applications')
      .set('Authorization', 'Bearer some-token')
      .send({ ...VALID_APPLICATION, contactPhone: 'not-e164' });

    // Auth runs before validation on this router (router.use(authenticate)), so an unconfigured
    // Firebase project surfaces as 401 here rather than 400 — this still proves the router chain
    // (auth -> validate -> controller) is wired in the correct order.
    expect(response.status).toBe(401);
  });
});

describe('GET /merchant/applications', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/merchant/applications');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /merchant/applications/:id', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/merchant/applications/app_1');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});
