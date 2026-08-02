'use strict';

// Bridges Surfboard's hosted Payment Page back into the Flutter app. Surfboard's `redirectUrl`/
// `failureRedirectUrl` (see payment.mapper.js#toOrderWire) must be public http(s) URLs — it
// rejects both custom schemes (e.g. `surfpos://...`) and private/loopback addresses outright
// (confirmed live). These two routes are the public http(s) targets Surfboard actually redirects
// the customer's browser to; they immediately 302 onward to this app's own `surfpos://payment/...`
// deep link, which Android Custom Tabs hands off to the app via its registered intent-filter (see
// frontend/android/.../AndroidManifest.xml) — the customer never sees an intermediate page.
//
// Per web-guides/payment-page.md: "Customer is redirected to your redirectUrl ... Includes
// orderId as a query param." Never trusted as a payment-success signal by itself — the frontend
// re-verifies the real status via GET /payments/checkout/:orderId/status before showing anything
// (see docs/15_SURFBOARD_INTEGRATION.md § 5.3, "Always verify server-side... do not rely solely
// on the redirect URL").

const { paymentTrace } = require('../utils/paymentTrace'); // TEMPORARY — see paymentTrace.js

const DEEP_LINK_SCHEME = 'surfpos://payment';

function buildDeepLink(outcome, query) {
  const orderId = typeof query.orderId === 'string' ? query.orderId : null;
  const params = orderId ? `?orderId=${encodeURIComponent(orderId)}` : '';
  return `${DEEP_LINK_SCHEME}/${outcome}${params}`;
}

function redirectSuccess(req, res) {
  paymentTrace(3, 'entered', { query: req.query });
  const deepLink = buildDeepLink('success', req.query);
  paymentTrace(4, 'exited', { orderId: req.query.orderId, deepLink });
  res.redirect(302, deepLink);
}

function redirectFailed(req, res) {
  paymentTrace(3, 'entered', { query: req.query });
  const deepLink = buildDeepLink('failed', req.query);
  paymentTrace(4, 'exited', { orderId: req.query.orderId, deepLink });
  res.redirect(302, deepLink);
}

module.exports = { redirectSuccess, redirectFailed };
