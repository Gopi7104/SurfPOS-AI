'use strict';

module.exports = {
  authClient: require('./auth.client'),
  merchantClient: require('./merchant.client'),
  paymentClient: require('./payment.client'),
  storeClient: require('./store.client'),
  deviceClient: require('./device.client'),
  brandingClient: require('./branding.client'),

  SurfboardBaseClient: require('./client/surfboardClient.base'),
  resolveSurfboardConfig: require('./client/surfboardConfig').resolveSurfboardConfig,
  SurfboardApiError: require('./errors/surfboardApiError'),
  verifyWebhookSignature: require('./utils/webhookSignatureVerifier').verifyWebhookSignature,

  AuthenticationManager: require('./auth/authenticationManager'),
  STRATEGY_TYPES: require('./auth/authStrategy').STRATEGY_TYPES,
  SurfboardAuthConfigError: require('./auth/authConfig').SurfboardAuthConfigError,
  ApiKeyStrategy: require('./auth/strategies/apiKeyStrategy'),
  BearerTokenStrategy: require('./auth/strategies/bearerTokenStrategy'),
  OAuthStrategy: require('./auth/strategies/oauthStrategy'),
  TokenProvider: require('./provider/tokenProvider'),
  TokenCache: require('./cache/tokenCache'),
};
