'use strict';

// Surfboard physical card-reader device API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardDeviceClient extends SurfboardBaseClient {
  // Future: linkDevice(), getDeviceStatus() — feeds payments/{paymentId}.surfboardDeviceId.
}

module.exports = new SurfboardDeviceClient();
