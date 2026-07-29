'use strict';

// The two Surfboard environments — mirrors config.surfboard.environment (see
// backend/src/config/index.js, SURFBOARD_ENV). Never mix credentials/base URLs across these.

module.exports = Object.freeze({
  SANDBOX: 'sandbox',
  PRODUCTION: 'production',
});
