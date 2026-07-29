'use strict';

// Verifies a Surfboard webhook signature — shared by whichever module owns a given webhook event
// type (payments today, potentially merchant/device status events later — see
// docs/15_SURFBOARD_INTEGRATION.md § 7). Not called from anywhere yet: no webhook route exists
// until Phase 9 (Payments) — see docs/22_DEVELOPMENT_ROADMAP.md.
//
// Placeholder scheme: HMAC-SHA256 over the raw request body, hex-encoded, timing-safe compared —
// a common convention, but Surfboard's *actual* signing scheme (header name, encoding, whether a
// timestamp is included in the signed payload) is unconfirmed against official docs (see
// docs/15_SURFBOARD_INTEGRATION.md § 7 accuracy note). Update this file once confirmed.

const { createHmac, timingSafeEqual } = require('crypto');

/**
 * @param {{ payload: string | Buffer, signature: string, secret: string }} args
 * @returns {boolean}
 */
function verifyWebhookSignature({ payload, signature, secret }) {
  if (!signature || !secret) {
    return false;
  }

  const expected = createHmac('sha256', secret).update(payload).digest('hex');
  const expectedBuffer = Buffer.from(expected, 'utf8');
  const providedBuffer = Buffer.from(signature, 'utf8');

  if (expectedBuffer.length !== providedBuffer.length) {
    return false;
  }

  return timingSafeEqual(expectedBuffer, providedBuffer);
}

module.exports = { verifyWebhookSignature };
