'use strict';

// Surfboard store-capabilities API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardStoreClient extends SurfboardBaseClient {
  // Future: getStoreCapabilities() — which payment methods/rails a given store supports.
}

module.exports = new SurfboardStoreClient();
