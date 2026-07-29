'use strict';

// Surfboard merchant onboarding/creation API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardMerchantClient extends SurfboardBaseClient {
  // Future: createMerchant(), getMerchant(), updateMerchant() — feeds merchants/{merchantId}.surfboardMerchantId.
}

module.exports = new SurfboardMerchantClient();
