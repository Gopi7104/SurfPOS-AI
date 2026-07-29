'use strict';

// OAuth2 client-credentials strategy for Surfboard's future token endpoint. The exact token URL,
// grant parameters, and response shape are unconfirmed (see docs/08_ARCHITECTURE_DECISIONS.md §
// ADR-009 open items) — this implements the standard client-credentials shape and isolates the
// guesswork to `tokenEndpointPath`/`parseTokenResponse`, so only this file needs updating once
// Surfboard's real OAuth docs are available. Deliberately does not route through
// SurfboardBaseClient: the token endpoint itself must not be authenticated with the token it's
// about to issue, and doing so would create a circular dependency between this SDK's auth layer
// and its request layer.

const TokenProvider = require('../../provider/tokenProvider');

const DEFAULT_TOKEN_ENDPOINT_PATH = '/oauth/token';

class OAuthStrategy {
  /**
   * @param {{
   *   baseUrl: string,
   *   apiKey: string,
   *   apiSecret: string,
   *   tokenEndpointPath?: string,
   *   fetchImpl?: typeof fetch,
   *   parseTokenResponse?: (data: object) => { token: string, expiresInSeconds: number },
   *   tokenProvider?: TokenProvider,
   * }} options
   */
  constructor({
    baseUrl,
    apiKey,
    apiSecret,
    tokenEndpointPath = DEFAULT_TOKEN_ENDPOINT_PATH,
    fetchImpl = fetch,
    parseTokenResponse = (data) => ({ token: data.access_token, expiresInSeconds: data.expires_in }),
    tokenProvider,
  } = {}) {
    if (!apiKey || !apiSecret) {
      throw new TypeError('OAuthStrategy requires both apiKey and apiSecret (client credentials)');
    }
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.apiSecret = apiSecret;
    this.tokenEndpointPath = tokenEndpointPath;
    this.fetchImpl = fetchImpl;
    this.parseTokenResponse = parseTokenResponse;

    this.tokenProvider =
      tokenProvider ||
      new TokenProvider({ fetchToken: () => this.fetchTokenFromSurfboard(), cacheKey: 'oauth' });
  }

  async fetchTokenFromSurfboard() {
    const response = await this.fetchImpl(`${this.baseUrl}${this.tokenEndpointPath}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        grant_type: 'client_credentials',
        client_id: this.apiKey,
        client_secret: this.apiSecret,
      }),
    });

    if (!response.ok) {
      throw new Error(`Surfboard OAuth token request failed with status ${response.status}`);
    }

    const data = await response.json();
    return this.parseTokenResponse(data);
  }

  /** @returns {Promise<Record<string, string>>} */
  async getAuthHeaders() {
    const token = await this.tokenProvider.getToken();
    return { Authorization: `Bearer ${token}` };
  }
}

module.exports = OAuthStrategy;
