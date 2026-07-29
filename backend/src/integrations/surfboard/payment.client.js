'use strict';

// Surfboard payment intent / payment status API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardPaymentClient extends SurfboardBaseClient {
  // Future: createPaymentIntent(), getPaymentStatus() — feeds payments/{paymentId}.
}

module.exports = new SurfboardPaymentClient();
