'use strict';

// Resolves Surfboard SDK configuration from backend env config — the only place environment
// switching (sandbox vs. production) and default timeout/retry values are decided.

const config = require('../../../config');
const ENVIRONMENT = require('../models/environment');

// Placeholder base URLs — confirm against Surfboard's official developer documentation before
// going live (see docs/15_SURFBOARD_INTEGRATION.md accuracy note).
const BASE_URLS = Object.freeze({
  [ENVIRONMENT.SANDBOX]: 'https://sandbox.api.surfboardpayments.com',
  [ENVIRONMENT.PRODUCTION]: 'https://api.surfboardpayments.com',
});

const DEFAULT_TIMEOUT_MS = 10_000;
const DEFAULT_MAX_RETRIES = 2;

/**
 * @returns {{ environment: string, baseUrl: string, apiKey?: string, apiSecret?: string, webhookSecret?: string, authStrategy: string, bearerToken?: string, partnerId?: string, secretKey?: string, timeoutMs: number, maxRetries: number }}
 */
function resolveSurfboardConfig() {
  const environment =
    config.surfboard.environment === ENVIRONMENT.PRODUCTION ? ENVIRONMENT.PRODUCTION : ENVIRONMENT.SANDBOX;

  return {
    environment,
    // SURFBOARD_API_URL (partner/white-label gateway) overrides the default sandbox/production
    // hosts when set — see docs/15_SURFBOARD_INTEGRATION.md § 2.
    baseUrl: config.surfboard.apiUrl || BASE_URLS[environment],
    apiKey: config.surfboard.apiKey,
    apiSecret: config.surfboard.apiSecret,
    webhookSecret: config.surfboard.webhookSecret,
    authStrategy: config.surfboard.authStrategy,
    bearerToken: config.surfboard.bearerToken,
    partnerId: config.surfboard.partnerId,
    secretKey: config.surfboard.secretKey,
    timeoutMs: DEFAULT_TIMEOUT_MS,
    maxRetries: DEFAULT_MAX_RETRIES,
  };
}

module.exports = { resolveSurfboardConfig, BASE_URLS };
