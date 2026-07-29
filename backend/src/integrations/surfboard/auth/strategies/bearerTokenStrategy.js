'use strict';

// Attaches a dynamic bearer token, sourced/cached/refreshed through a TokenProvider. By default
// resolves a statically configured long-lived token (SURFBOARD_BEARER_TOKEN); inject a custom
// `fetchToken` (or a fully-formed `tokenProvider`) to source the token elsewhere — e.g. once a
// real Surfboard token-issuing endpoint is confirmed, without changing this strategy's shape.

const TokenProvider = require('../../provider/tokenProvider');

class BearerTokenStrategy {
  /**
   * @param {{
   *   bearerToken?: string,
   *   fetchToken?: () => Promise<{ token: string, expiresInSeconds: number }>,
   *   tokenProvider?: TokenProvider,
   * }} [options]
   */
  constructor({ bearerToken, fetchToken, tokenProvider } = {}) {
    const resolvedFetchToken =
      fetchToken ||
      (bearerToken
        ? async () => ({ token: bearerToken, expiresInSeconds: Number.POSITIVE_INFINITY })
        : undefined);

    if (!resolvedFetchToken && !tokenProvider) {
      throw new TypeError('BearerTokenStrategy requires a bearerToken, a fetchToken(), or a tokenProvider');
    }

    this.tokenProvider =
      tokenProvider || new TokenProvider({ fetchToken: resolvedFetchToken, cacheKey: 'bearer' });
  }

  /** @returns {Promise<Record<string, string>>} */
  async getAuthHeaders() {
    const token = await this.tokenProvider.getToken();
    return { Authorization: `Bearer ${token}` };
  }
}

module.exports = BearerTokenStrategy;
