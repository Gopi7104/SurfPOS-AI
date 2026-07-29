'use strict';

// Shared contract every Surfboard authentication strategy implements — see
// docs/08_ARCHITECTURE_DECISIONS.md for why this is a strategy pattern rather than an if/else in
// the request pipeline: swapping api_key/bearer/oauth, or adding a new scheme once Surfboard's
// real docs are confirmed, never touches SurfboardBaseClient or any domain client.

const STRATEGY_TYPES = Object.freeze({
  API_KEY: 'api_key',
  BEARER: 'bearer',
  OAUTH: 'oauth',
});

/**
 * @typedef {object} AuthStrategy
 * @property {() => Promise<Record<string, string>>} getAuthHeaders resolves the header(s) to
 *   attach to an outgoing Surfboard request for this strategy.
 */

/** @param {Partial<AuthStrategy>} strategy */
function assertValidStrategy(strategy) {
  if (!strategy || typeof strategy.getAuthHeaders !== 'function') {
    throw new TypeError('An auth strategy must implement getAuthHeaders()');
  }
}

module.exports = { STRATEGY_TYPES, assertValidStrategy };
