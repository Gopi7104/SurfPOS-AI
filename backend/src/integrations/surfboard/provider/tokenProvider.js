'use strict';

// Turns a strategy-supplied token fetcher into a cached, auto-refreshing token source. Any
// auth strategy that deals in expiring tokens (bearer, oauth) owns one TokenProvider instance —
// see docs/21_BACKEND_GUIDELINES.md § 12 for the constructor-injection pattern this follows.

const TokenCache = require('../cache/tokenCache');
const { createTokenRefreshStrategy } = require('./tokenRefreshStrategy');

class TokenProvider {
  /**
   * @param {{
   *   fetchToken: () => Promise<{ token: string, expiresInSeconds: number }>,
   *   cache?: TokenCache,
   *   cacheKey?: string,
   *   refreshStrategy?: ReturnType<typeof createTokenRefreshStrategy>,
   * }} deps
   */
  constructor({
    fetchToken,
    cache = new TokenCache(),
    cacheKey = 'default',
    refreshStrategy = createTokenRefreshStrategy(),
  } = {}) {
    if (typeof fetchToken !== 'function') {
      throw new TypeError('TokenProvider requires a fetchToken() function');
    }
    this.fetchToken = fetchToken;
    this.cache = cache;
    this.cacheKey = cacheKey;
    this.refreshStrategy = refreshStrategy;
  }

  /**
   * Returns a valid token, transparently fetching/refreshing it if missing or near expiry.
   * Concurrent callers during a refresh all resolve from the same in-flight fetch.
   * @returns {Promise<string>}
   */
  async getToken() {
    return this.cache.getOrCreate(this.cacheKey, async () => {
      const { token, expiresInSeconds } = await this.fetchToken();
      const expiresAt = this.refreshStrategy.computeCacheExpiry(expiresInSeconds);
      return { value: token, expiresAt };
    });
  }

  /** Forces the next getToken() call to fetch a new token instead of using the cache. */
  invalidate() {
    this.cache.clear(this.cacheKey);
  }
}

module.exports = TokenProvider;
