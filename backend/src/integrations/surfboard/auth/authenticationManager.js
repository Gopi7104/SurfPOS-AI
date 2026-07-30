'use strict';

// Selects and owns the active Surfboard authentication strategy so the request pipeline never
// branches on auth scheme itself — it just calls getAuthHeaders(). Swapping api_key/bearer/oauth
// (SURFBOARD_AUTH_STRATEGY), or registering a brand new strategy, never touches
// SurfboardBaseClient or any domain client (see docs/08_ARCHITECTURE_DECISIONS.md new ADR).
//
// Dependencies are injected with real implementations as defaults (docs/21_BACKEND_GUIDELINES.md
// § 12) so tests can substitute fake strategy factories without touching real credentials.

const { STRATEGY_TYPES, assertValidStrategy } = require('./authStrategy');
const { validateAuthConfig } = require('./authConfig');
const { loadCredentials } = require('./credentialLoader');
const ApiKeyStrategy = require('./strategies/apiKeyStrategy');
const ApiKeySecretStrategy = require('./strategies/apiKeySecretStrategy');
const BearerTokenStrategy = require('./strategies/bearerTokenStrategy');
const OAuthStrategy = require('./strategies/oauthStrategy');

const DEFAULT_STRATEGY_FACTORIES = Object.freeze({
  [STRATEGY_TYPES.API_KEY]: ({ credentials }) => new ApiKeyStrategy({ apiKey: credentials.apiKey }),
  [STRATEGY_TYPES.API_KEY_SECRET]: ({ credentials }) =>
    new ApiKeySecretStrategy({ apiKey: credentials.apiKey, apiSecret: credentials.apiSecret }),
  [STRATEGY_TYPES.BEARER]: ({ credentials }) =>
    new BearerTokenStrategy({ bearerToken: credentials.bearerToken }),
  [STRATEGY_TYPES.OAUTH]: ({ credentials, config }) =>
    new OAuthStrategy({
      baseUrl: config.baseUrl,
      apiKey: credentials.apiKey,
      apiSecret: credentials.apiSecret,
    }),
});

class AuthenticationManager {
  /**
   * @param {{
   *   config: { authStrategy?: string, baseUrl?: string, apiKey?: string, apiSecret?: string, bearerToken?: string },
   *   strategyFactories?: Record<string, (ctx: { credentials: object, config: object }) => import('./authStrategy').AuthStrategy>,
   * }} deps
   */
  constructor({ config = {}, strategyFactories = DEFAULT_STRATEGY_FACTORIES } = {}) {
    const strategyName = config.authStrategy || STRATEGY_TYPES.API_KEY;
    const credentials = loadCredentials(config);

    // Built-in strategies get fail-fast credential validation; a custom strategy registered via
    // `strategyFactories` owns its own validation — this manager only knows the built-in shapes.
    if (Object.values(STRATEGY_TYPES).includes(strategyName)) {
      validateAuthConfig(strategyName, credentials);
    }

    const factory = strategyFactories[strategyName];
    if (!factory) {
      throw new TypeError(`No auth strategy factory registered for "${strategyName}"`);
    }

    this.strategyName = strategyName;
    this.strategy = factory({ credentials, config });
    assertValidStrategy(this.strategy);
  }

  /** @returns {Promise<Record<string, string>>} */
  async getAuthHeaders() {
    return this.strategy.getAuthHeaders();
  }
}

module.exports = AuthenticationManager;
module.exports.DEFAULT_STRATEGY_FACTORIES = DEFAULT_STRATEGY_FACTORIES;
