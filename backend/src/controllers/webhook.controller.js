'use strict';

// Receives Surfboard's per-order webhook (the `controlFunctions.callBackUrl` set in
// payment.service.js#buildRedirectUrls) — see docs/04_API_DOCUMENTATION.md § 10 and
// web-guides/webhooks-notifications.md. Only reachable when PUBLIC_BASE_URL is configured, since
// Surfboard never receives a callBackUrl otherwise (see payment.service.js#buildRedirectUrls).
//
// This only verifies the signature and logs the event for now — there is no Sale/order
// persistence layer in this app yet (out of scope for Payment Integration, Roadmap Phase 4), so
// there is nothing to update here. The Flutter app's own status polling
// (GET /payments/checkout/:orderId/status) remains the source of truth for payment state; per
// web-guides/webhooks-notifications.md's own documented fallback, that's expected — a webhook is
// a faster-than-polling notification, not the only way to learn the outcome.

const { sendSuccess, sendError } = require('../utils/response');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../constants');
const { verifyWebhookSignature } = require('../integrations/surfboard/utils/webhookSignatureVerifier');
const config = require('../config');
const { logger } = require('../utils/logger');

function receiveSurfboardWebhook(req, res) {
  const signature = req.headers['x-webhook-signature'];

  if (!signature) {
    return sendError(res, {
      code: ERROR_CODES.UNAUTHENTICATED,
      message: MESSAGES.MISSING_WEBHOOK_SIGNATURE,
      statusCode: HTTP_STATUS.UNAUTHORIZED,
    });
  }

  const isValid = verifyWebhookSignature({
    payload: req.rawBody,
    signature,
    secret: config.surfboard.webhookSecret,
  });

  if (!isValid) {
    return sendError(res, {
      code: ERROR_CODES.UNAUTHENTICATED,
      message: MESSAGES.INVALID_WEBHOOK_SIGNATURE,
      statusCode: HTTP_STATUS.UNAUTHORIZED,
    });
  }

  logger.info({ event: req.body }, 'Received Surfboard webhook');
  return sendSuccess(res, { received: true });
}

module.exports = { receiveSurfboardWebhook };
