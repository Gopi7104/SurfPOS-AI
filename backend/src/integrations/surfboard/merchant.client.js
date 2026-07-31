'use strict';

// Surfboard merchant onboarding/creation API — see docs/15_SURFBOARD_INTEGRATION.md,
// docs/19_SURFBOARD_WORKFLOWS.md § 1. Wire format confirmed against the real Surfboard docs
// (Create Merchant, Check Application Status, Fetch/Update Merchant Details) — see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-025. Isolated to this file + merchant.mapper.js per
// ADR-009/ADR-018's original isolation intent, now resolved rather than still-pending.

const SurfboardBaseClient = require('./client/surfboardClient.base');

const merchantsPath = (partnerId) => `/partners/${partnerId}/merchants`;
const merchantPath = (partnerId, merchantId) => `/partners/${partnerId}/merchants/${merchantId}`;
const applicationStatusPath = (partnerId, applicationId) =>
  `/partners/${partnerId}/merchants/${applicationId}/status`;

class SurfboardMerchantClient extends SurfboardBaseClient {
  /**
   * Submits a merchant application to Surfboard. Onboarding is asynchronous (KYB review) — the
   * response only ever carries an `applicationId`/`webKybUrl` (+ `merchantId`/`storeId` for
   * already-approved partner types), never a status; poll via `getApplicationStatus()`. The raw
   * response shape is normalized by mappers/merchant.mapper.js, not here.
   * @param {object} wirePayload — already in Surfboard's wire format (see merchant.mapper.js#toWire)
   * @returns {Promise<object>} raw Surfboard response body ({ status, data, message })
   */
  async createMerchant(wirePayload) {
    const { data } = await this.request({
      method: 'POST',
      path: merchantsPath(this.config.partnerId),
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Polls the Check Application Status endpoint — the only source of the real
   * `applicationStatus` enum (`APPLICATION_INITIATED` ... `MERCHANT_CREATED`); Create Merchant's
   * own response never carries one.
   * @param {string} applicationId
   * @returns {Promise<object>} raw Surfboard response body ({ status, data, message })
   */
  async getApplicationStatus(applicationId) {
    const { data } = await this.request({
      method: 'GET',
      path: applicationStatusPath(this.config.partnerId, applicationId),
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Fetches the current Merchant profile — live, never cached in Firebase beyond the minimal
   * reference (docs/20_DOMAIN_MODEL.md § 1). Requires the `MERCHANT-ID` header in addition to the
   * usual auth headers (confirmed from docs) — this is the one Surfboard call that needs a header
   * beyond what the auth strategy attaches, so it's passed through `request()`'s `headers` option
   * rather than added to the auth strategy itself (auth headers are identity, this is a target).
   * @param {string} merchantId
   * @returns {Promise<object>} raw Surfboard response body
   */
  async getMerchant(merchantId) {
    const { data } = await this.request({
      method: 'GET',
      path: merchantPath(this.config.partnerId, merchantId),
      headers: { 'MERCHANT-ID': merchantId },
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * @param {string} merchantId
   * @param {object} wirePayload — already in Surfboard's wire format (see merchant.mapper.js#toMerchantUpdateWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async updateMerchant(merchantId, wirePayload) {
    const { data } = await this.request({
      method: 'PUT',
      path: merchantPath(this.config.partnerId, merchantId),
      headers: { 'MERCHANT-ID': merchantId },
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }
}

module.exports = new SurfboardMerchantClient();
module.exports.SurfboardMerchantClient = SurfboardMerchantClient;
