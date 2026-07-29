'use strict';

// Decides how long a freshly-fetched token is allowed to sit in TokenCache before TokenProvider
// treats it as expired and refreshes it early — a safety margin so a request never races a token
// that expires mid-flight at the Surfboard end.

const DEFAULT_REFRESH_SKEW_MS = 30_000;

/**
 * @param {{ refreshSkewMs?: number }} [options]
 */
function createTokenRefreshStrategy({ refreshSkewMs = DEFAULT_REFRESH_SKEW_MS } = {}) {
  /**
   * @param {number} expiresInSeconds seconds-until-expiry as reported by the token issuer
   * @param {number} [now] epoch ms, injectable for tests
   * @returns {number} the epoch-ms TokenCache should treat this token as expired
   */
  function computeCacheExpiry(expiresInSeconds, now = Date.now()) {
    const hardExpiresAt = now + Math.max(0, expiresInSeconds) * 1000;
    return Math.max(now, hardExpiresAt - refreshSkewMs);
  }

  return { computeCacheExpiry, refreshSkewMs };
}

module.exports = { createTokenRefreshStrategy, DEFAULT_REFRESH_SKEW_MS };
