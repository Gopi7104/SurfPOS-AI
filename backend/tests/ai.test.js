import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// Same rationale as tests/inventory.test.js: no Firebase project is provisioned in this
// environment, so these route-level tests exercise real validation/auth-middleware wiring; full
// business-logic coverage lives in tests/modules/ai/ai.service.test.js against a fake
// OpenRouter client.

describe('POST /ai/chat', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app)
      .post('/ai/chat')
      .send({ messages: [{ role: 'user', content: 'Hi' }] });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('GET /ai/status', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).get('/ai/status');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});

describe('POST /ai/status/test', () => {
  it('returns 401 UNAUTHENTICATED without an Authorization header', async () => {
    const response = await request(app).post('/ai/status/test');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
  });
});
