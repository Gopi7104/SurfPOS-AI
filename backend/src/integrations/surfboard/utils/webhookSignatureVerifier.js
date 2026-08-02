'use strict';

// Verifies a Surfboard webhook signature — shared by whichever module owns a given webhook event
// type (payments today, potentially merchant/device status events later — see
// docs/15_SURFBOARD_INTEGRATION.md § 7). Confirmed against the real bundled docs
// (web-guides/webhooks-notifications.md § "Verifying Webhook Signatures", same source used
// throughout this integration): HMAC-SHA512 over the raw JSON request body, Base64-encoded,
// carried in the `x-webhook-signature` header. `payload` must be the exact raw bytes Express
// received (see app.js's `express.json({ verify })`) — re-serializing the parsed body could
// reorder keys/whitespace and silently break the signature.

const { createHmac, timingSafeEqual } = require('crypto');

/**
 * @param {{ payload: string | Buffer, signature: string, secret: string }} args
 * @returns {boolean}
 */
function verifyWebhookSignature({ payload, signature, secret }) {
  if (!signature || !secret) {
    return false;
  }

  const expectedBuffer = createHmac('sha512', secret).update(payload).digest();
  let providedBuffer;
  try {
    providedBuffer = Buffer.from(signature, 'base64');
  } catch {
    return false;
  }

  if (expectedBuffer.length !== providedBuffer.length) {
    return false;
  }

  return timingSafeEqual(expectedBuffer, providedBuffer);
}

module.exports = { verifyWebhookSignature };
