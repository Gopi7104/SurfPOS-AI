'use strict';

// In-memory TTL cache for Surfboard auth tokens, with single-flight refresh so concurrent
// requests during a cache miss/expiry trigger exactly one upstream token fetch, not one each.
// Scoped to a single process — fine for this SDK's use case (one backend instance per token
// issuer), see docs/08_ARCHITECTURE_DECISIONS.md for the ADR on this layer.

class TokenCache {
  constructor() {
    this.entries = new Map();
    this.pending = new Map();
  }

  /**
   * @param {string} key
   * @returns {any|undefined} the cached value, or undefined if missing/expired
   */
  get(key) {
    const entry = this.entries.get(key);
    if (!entry) {
      return undefined;
    }
    if (Date.now() >= entry.expiresAt) {
      this.entries.delete(key);
      return undefined;
    }
    return entry.value;
  }

  /**
   * @param {string} key
   * @param {any} value
   * @param {number} expiresAt epoch ms
   */
  set(key, value, expiresAt) {
    this.entries.set(key, { value, expiresAt });
  }

  /** @param {string} [key] clears one entry, or the whole cache if omitted */
  clear(key) {
    if (key === undefined) {
      this.entries.clear();
      this.pending.clear();
      return;
    }
    this.entries.delete(key);
    this.pending.delete(key);
  }

  /**
   * Returns the cached value for `key` if still fresh; otherwise calls `factory` to obtain a
   * fresh one. Concurrent calls for the same key while a factory call is in flight all await
   * the same promise instead of triggering a duplicate upstream fetch.
   * @param {string} key
   * @param {() => Promise<{ value: any, expiresAt: number }>} factory
   * @returns {Promise<any>}
   */
  async getOrCreate(key, factory) {
    const cached = this.get(key);
    if (cached !== undefined) {
      return cached;
    }

    if (this.pending.has(key)) {
      return this.pending.get(key);
    }

    const inflight = (async () => {
      try {
        const { value, expiresAt } = await factory();
        this.set(key, value, expiresAt);
        return value;
      } finally {
        this.pending.delete(key);
      }
    })();

    this.pending.set(key, inflight);
    return inflight;
  }
}

module.exports = TokenCache;
