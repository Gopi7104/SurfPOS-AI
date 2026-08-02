'use strict';

// Receives Surfboard's per-order webhook (the `controlFunctions.callBackUrl` set in
// payment.service.js#buildRedirectUrls) — see docs/04_API_DOCUMENTATION.md § 10 and
// web-guides/webhooks-notifications.md. Only reachable when PUBLIC_BASE_URL is configured, since
// Surfboard never receives a callBackUrl otherwise (see payment.service.js#buildRedirectUrls).
//
// Confirmed live: Surfboard's hosted Payment Page can redirect the customer back into the app
// (a real completed payment) well before Fetch Order Status reflects that same completion —
// observed lags from tens of seconds up to multiple minutes on the sandbox. The Flutter app polls
// that same endpoint every 2s for up to 3 minutes, so a long enough lag makes it give up
// ("Payment Expired"/error) despite the payment having actually succeeded. This webhook carries
// the exact same outcome with none of that lag (it's the event itself, not a queryable projection
// of one) — so a terminal event's outcome is cached here, and payment.service.js#getCheckoutStatus
// now checks that cache FIRST, before ever calling the (possibly-lagging) Fetch Order Status API.
// Non-terminal events (Order Updated, Payment Initiated/Processed) are intentionally ignored —
// `toWebhookStatusDomain` returns `null` for anything but the three terminal ones, and per
// web-guides/webhooks-notifications.md's "Handling Duplicate Deliveries" section, a terminal
// status must never be overwritten by an earlier/non-terminal one, so there is nothing useful to
// cache for those.

const { sendSuccess, sendError } = require('../utils/response');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../constants');
const { verifyWebhookSignature } = require('../integrations/surfboard/utils/webhookSignatureVerifier');
const config = require('../config');
const { logger } = require('../utils/logger');
const mapper = require('../integrations/surfboard/mappers/payment.mapper');
const paymentRepository = require('../modules/payments/payment.repository');

async function receiveSurfboardWebhook(req, res) {
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

  const status = mapper.toWebhookStatusDomain(req.body);
  if (status) {
    await paymentRepository.setWebhookStatus(status.orderId, status);
    logger.info(
      { orderId: status.orderId, paymentStatus: status.paymentStatus },
      'Cached terminal payment status from webhook',
    );
  }

  return sendSuccess(res, { received: true });
}

module.exports = { receiveSurfboardWebhook };
