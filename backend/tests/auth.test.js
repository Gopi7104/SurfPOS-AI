import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// This environment has no Firebase project provisioned yet (see docs/22_DEVELOPMENT_ROADMAP.md
// Prerequisites), and this project's Vitest/CJS require() graph doesn't reliably honor vi.mock()
// on a nested require('../../firebase/admin') call (the same class of module-boundary quirk
// already noted in docs/09_PROMPT_HISTORY.md's Phase 2 entry) — so these route-level tests
// exercise real validation/auth-middleware wiring, and confirm Firebase-touching paths reach the
// service correctly by asserting the deterministic "not configured" boundary rather than mocking
// Firebase. Full signUp/login/getCurrentUser/logout business-logic coverage — including every
// success and mapped-error path — lives in tests/modules/auth/auth.service.test.js against fake
// Firebase/repository dependencies (docs/21_BACKEND_GUIDELINES.md § 11).

describe('POST /auth/signup', () => {
  it('returns 400 VALIDATION_ERROR for a missing password', async () => {
    const response = await request(app).post('/auth/signup').send({ email: 'owner@example.com' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 400 VALIDATION_ERROR for a malformed email', async () => {
    const response = await request(app)
      .post('/auth/signup')
      .send({ email: 'not-an-email', password: 'supersecret' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('reaches the auth service for a well-formed request (Firebase unconfigured in this env)', async () => {
    const response = await request(app)
      .post('/auth/signup')
      .send({ email: 'owner@example.com', password: 'supersecret' });

    expect(response.status).toBe(500);
    expect(response.body.error.message).toMatch(/Firebase Admin SDK is not configured/);
  });
});

describe('POST /auth/login', () => {
  it('returns 400 VALIDATION_ERROR for a missing idToken', async () => {
    const response = await request(app).post('/auth/login').send({});

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('reaches the auth service for a well-formed request (fails safe as unauthenticated)', async () => {
    const response = await request(app).post('/auth/login').send({ idToken: 'some-token' });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /auth/me', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/auth/me');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('returns 401 UNAUTHENTICATED for a malformed Authorization header', async () => {
    const response = await request(app).get('/auth/me').set('Authorization', 'not-bearer-shaped');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('reaches the auth middleware for a Bearer-shaped token (fails safe as unauthenticated)', async () => {
    const response = await request(app).get('/auth/me').set('Authorization', 'Bearer some-token');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('POST /auth/logout', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).post('/auth/logout');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});
