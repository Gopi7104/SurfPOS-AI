'use strict';

// API version prefix — see docs/04_API_DOCUMENTATION.md § 1 (base URL .../api/v1).
// Not yet applied to any route (only GET /health exists, deliberately unversioned — see
// docs/04_API_DOCUMENTATION.md § 13); future business-module routers mount under API_VERSION.PREFIX.

module.exports = Object.freeze({
  CURRENT: 'v1',
  PREFIX: '/api/v1',
});
