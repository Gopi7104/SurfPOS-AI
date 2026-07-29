'use strict';

// Surfboard receipt/checkout branding API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardBrandingClient extends SurfboardBaseClient {
  // Future: getBranding(), updateBranding() — merchant-facing branding config, if Surfboard exposes one.
}

module.exports = new SurfboardBrandingClient();
