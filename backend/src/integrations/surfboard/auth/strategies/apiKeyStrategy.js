'use strict';

// Attaches the platform-level Surfboard API key as a request header. The wire format (a
// Bearer-style Authorization header vs. a dedicated X-Api-Key header) is unconfirmed against
// Surfboard's official docs (see docs/15_SURFBOARD_INTEGRATION.md § 2) — defaults to the
// Bearer-style header the SDK has assumed since Phase 2 so default behavior doesn't change;
// pass `headerName`/`formatValue` to override once the real scheme is confirmed.

class ApiKeyStrategy {
  /**
   * @param {{ apiKey: string, headerName?: string, formatValue?: (apiKey: string) => string }} options
   */
  constructor({ apiKey, headerName = 'Authorization', formatValue = (key) => `Bearer ${key}` } = {}) {
    if (!apiKey) {
      throw new TypeError('ApiKeyStrategy requires an apiKey');
    }
    this.apiKey = apiKey;
    this.headerName = headerName;
    this.formatValue = formatValue;
  }

  /** @returns {Promise<Record<string, string>>} */
  async getAuthHeaders() {
    return { [this.headerName]: this.formatValue(this.apiKey) };
  }
}

module.exports = ApiKeyStrategy;
