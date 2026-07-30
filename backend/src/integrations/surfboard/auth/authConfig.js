'use strict';

// Fail-fast validation of the credentials a chosen Surfboard auth strategy actually needs.
// src/config/index.js already enforces which env keys are hard-required in production; this
// checks strategy-specific combinations that depend on which strategy was selected, which
// config/index.js has no way to know about.

const { STRATEGY_TYPES } = require('./authStrategy');

class SurfboardAuthConfigError extends Error {
  constructor(message) {
    super(message);
    this.name = 'SurfboardAuthConfigError';
  }
}

/**
 * @param {string} strategy one of STRATEGY_TYPES
 * @param {{ apiKey?: string, apiSecret?: string, bearerToken?: string }} credentials
 */
function validateAuthConfig(strategy, credentials = {}) {
  switch (strategy) {
    case STRATEGY_TYPES.API_KEY:
      if (!credentials.apiKey) {
        throw new SurfboardAuthConfigError(
          'SURFBOARD_AUTH_STRATEGY=api_key requires SURFBOARD_API_KEY to be set',
        );
      }
      return;

    case STRATEGY_TYPES.API_KEY_SECRET:
      if (!credentials.apiKey || !credentials.apiSecret) {
        throw new SurfboardAuthConfigError(
          'SURFBOARD_AUTH_STRATEGY=api_key_secret requires both SURFBOARD_API_KEY and SURFBOARD_API_SECRET',
        );
      }
      return;

    case STRATEGY_TYPES.BEARER:
      if (!credentials.bearerToken) {
        throw new SurfboardAuthConfigError(
          'SURFBOARD_AUTH_STRATEGY=bearer requires SURFBOARD_BEARER_TOKEN to be set ' +
            '(or inject a custom fetchToken into BearerTokenStrategy for a dynamic token source)',
        );
      }
      return;

    case STRATEGY_TYPES.OAUTH:
      if (!credentials.apiKey || !credentials.apiSecret) {
        throw new SurfboardAuthConfigError(
          'SURFBOARD_AUTH_STRATEGY=oauth requires both SURFBOARD_API_KEY and SURFBOARD_API_SECRET (client credentials)',
        );
      }
      return;

    default:
      throw new SurfboardAuthConfigError(`Unknown Surfboard auth strategy "${strategy}"`);
  }
}

module.exports = { validateAuthConfig, SurfboardAuthConfigError };
