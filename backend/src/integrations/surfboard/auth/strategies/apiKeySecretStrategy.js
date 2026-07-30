'use strict';

// Confirmed Surfboard auth scheme for the Merchant Onboarding API family (Create Merchant, Check
// Application Status, Fetch/Update Merchant Details) — see docs/08_ARCHITECTURE_DECISIONS.md §
// ADR-025. Unlike apiKeyStrategy.js's single Bearer-style guess, this sends both credentials as
// their own headers simultaneously, exactly as the confirmed docs specify — no customizable
// header name/formatValue, since this is no longer a guess.

class ApiKeySecretStrategy {
  /**
   * @param {{ apiKey: string, apiSecret: string }} options
   */
  constructor({ apiKey, apiSecret } = {}) {
    if (!apiKey) {
      throw new TypeError('ApiKeySecretStrategy requires an apiKey');
    }
    if (!apiSecret) {
      throw new TypeError('ApiKeySecretStrategy requires an apiSecret');
    }
    this.apiKey = apiKey;
    this.apiSecret = apiSecret;
  }

  /** @returns {Promise<Record<string, string>>} */
  async getAuthHeaders() {
    return { 'API-KEY': this.apiKey, 'API-SECRET': this.apiSecret };
  }
}

module.exports = ApiKeySecretStrategy;
