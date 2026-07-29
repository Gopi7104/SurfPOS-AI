'use strict';

// Surfboard client-authentication API — see docs/15_SURFBOARD_INTEGRATION.md.
// Placeholder client architecture only; no API calls implemented yet (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009).

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardAuthClient extends SurfboardBaseClient {
  // Future: authenticate(), refreshToken() — once the Surfboard auth flow is confirmed.
}

module.exports = new SurfboardAuthClient();
