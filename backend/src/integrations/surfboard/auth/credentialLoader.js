'use strict';

// The one place Surfboard credentials are read out of resolved SDK config for authentication
// purposes — never read process.env directly outside here or src/config/index.js (see
// docs/07_CODING_RULES.md § 15). Also owns redaction so a credential value never reaches a log
// line unmasked (docs/21_BACKEND_GUIDELINES.md § 10).

/**
 * @param {{ apiKey?: string, apiSecret?: string, bearerToken?: string }} config
 * @returns {{ apiKey?: string, apiSecret?: string, bearerToken?: string }}
 */
function loadCredentials(config = {}) {
  return {
    apiKey: config.apiKey,
    apiSecret: config.apiSecret,
    bearerToken: config.bearerToken,
  };
}

/**
 * Masks all but the last 4 characters of a secret, for safe inclusion in logs/errors.
 * @param {string|undefined} secret
 * @returns {string|undefined}
 */
function redact(secret) {
  if (!secret) {
    return undefined;
  }
  if (secret.length <= 4) {
    return '****';
  }
  return `${'*'.repeat(secret.length - 4)}${secret.slice(-4)}`;
}

module.exports = { loadCredentials, redact };
