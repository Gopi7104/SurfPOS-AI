import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

// This environment has no SURFBOARD_WEBHOOK_SECRET provisioned (see docs/22_DEVELOPMENT_ROADMAP.md
// Prerequisites) — same deterministic "unconfigured" boundary tests/auth.test.js already relies on
// rather than mocking config. Full signature verification correctness (real HMAC-SHA512/Base64
// matches, tampering, wrong secret) is unit-tested directly against a real secret in
// tests/integrations/surfboard/webhookSignatureVerifier.test.js.

describe('POST /webhooks/surfboard', () => {
  it('returns 401 UNAUTHENTICATED when the signature header is missing', async () => {
    const response = await request(app).post('/webhooks/surfboard').send({ event: 'payment.succeeded' });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
    expect(response.body.error.message).toMatch(/x-webhook-signature/i);
  });

  it('returns 401 UNAUTHENTICATED when the signature does not verify (no secret configured in this env)', async () => {
    const response = await request(app)
      .post('/webhooks/surfboard')
      .set('x-webhook-signature', 'deadbeef')
      .send({ event: 'payment.succeeded' });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('UNAUTHENTICATED');
    expect(response.body.error.message).toMatch(/invalid webhook signature/i);
  });
});
