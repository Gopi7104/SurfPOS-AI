'use strict';

// Surfboard merchant onboarding/creation API — see docs/15_SURFBOARD_INTEGRATION.md,
// docs/19_SURFBOARD_WORKFLOWS.md § 1. Wire format is unconfirmed against official Surfboard docs
// (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) — isolated to this file + merchant.mapper.js so
// confirming it later is a two-file change, not a rewrite of modules/merchant/.

const SurfboardBaseClient = require('./client/surfboardClient.base');

const CREATE_MERCHANT_PATH = '/merchants';
const merchantPath = (merchantId) => `/merchants/${merchantId}`;

class SurfboardMerchantClient extends SurfboardBaseClient {
  /**
   * Submits a merchant application to Surfboard. Onboarding may be asynchronous (KYC review) —
   * the raw response shape is normalized by mappers/merchant.mapper.js, not here.
   * @param {object} wirePayload — already in Surfboard's wire format (see merchant.mapper.js#toWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async createMerchant(wirePayload) {
    const { data } = await this.request({ method: 'POST', path: CREATE_MERCHANT_PATH, body: wirePayload });
    return data;
  }

  /**
   * Fetches the current Merchant profile — live, never cached in Firebase beyond the minimal
   * reference (docs/20_DOMAIN_MODEL.md § 1). Also the basis for the normalized "status" view
   * (Roadmap Phase 5 § 3) — Surfboard's docs don't define a separate status endpoint, so no
   * separate wire call is assumed for it (see docs/08_ARCHITECTURE_DECISIONS.md § ADR-022).
   * @param {string} merchantId
   * @returns {Promise<object>} raw Surfboard response body
   */
  async getMerchant(merchantId) {
    const { data } = await this.request({ method: 'GET', path: merchantPath(merchantId) });
    return data;
  }

  /**
   * @param {string} merchantId
   * @param {object} wirePayload — already in Surfboard's wire format (see merchant.mapper.js#toMerchantUpdateWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async updateMerchant(merchantId, wirePayload) {
    const { data } = await this.request({
      method: 'PATCH',
      path: merchantPath(merchantId),
      body: wirePayload,
    });
    return data;
  }
}

module.exports = new SurfboardMerchantClient();
module.exports.SurfboardMerchantClient = SurfboardMerchantClient;
