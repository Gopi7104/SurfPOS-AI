import { describe, it, expect } from 'vitest';
import { createHmac } from 'crypto';
import { verifyWebhookSignature } from '../../../src/integrations/surfboard/utils/webhookSignatureVerifier.js';

function sign(payload, secret) {
  return createHmac('sha256', secret).update(payload).digest('hex');
}

describe('verifyWebhookSignature', () => {
  it('returns true for a correctly signed payload', () => {
    const payload = JSON.stringify({ event: 'payment.succeeded' });
    const secret = 'whsec_test';

    expect(verifyWebhookSignature({ payload, signature: sign(payload, secret), secret })).toBe(true);
  });

  it('returns false when the signature does not match', () => {
    const payload = JSON.stringify({ event: 'payment.succeeded' });

    expect(verifyWebhookSignature({ payload, signature: 'deadbeef', secret: 'whsec_test' })).toBe(false);
  });

  it('returns false when the payload was tampered with', () => {
    const secret = 'whsec_test';
    const signature = sign(JSON.stringify({ event: 'payment.succeeded' }), secret);

    expect(
      verifyWebhookSignature({ payload: JSON.stringify({ event: 'payment.failed' }), signature, secret }),
    ).toBe(false);
  });

  it('returns false when the signature is missing', () => {
    expect(verifyWebhookSignature({ payload: 'x', signature: '', secret: 'whsec_test' })).toBe(false);
  });

  it('returns false when the secret is missing', () => {
    expect(verifyWebhookSignature({ payload: 'x', signature: 'abc', secret: '' })).toBe(false);
  });
});
