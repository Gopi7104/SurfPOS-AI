'use strict';

// Surfboard store-capabilities API — see docs/15_SURFBOARD_INTEGRATION.md,
// docs/19_SURFBOARD_WORKFLOWS.md § 2.
//
// getStore()/updateStore() are confirmed against the real Surfboard docs bundled in
// `node_modules/@surfboardpayments/surf-mcp/data/api-md/stores-{fetch,update}-store-details.md`
// (the same source used to confirm the Merchant family — see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-025): both are
// `.../partners/:partnerId/merchants/:merchantId/stores/:storeId` with a required `MERCHANT-ID`
// header, sharing the `{status, data, message}` envelope — GET to fetch, PUT to update.
// updateStore() was previously an unconfirmed guess (`PATCH /stores/:storeId`, no MERCHANT-ID
// header) that had never been exercised by any live flow — corrected as part of diagnosing the
// "TM_0029: Onboarding is not completed for the store" Checkout failure (see
// payment.service.js#ensureStoreOnlineInfo), which requires a *working* updateStore() to set a
// store's `onlineInfo` before it can accept online payments. createStore()'s wire format is still
// unconfirmed (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) — it isn't called from any live flow
// today (Surfboard creates a Store as a side effect of Create Merchant's `controlFields.store`
// instead, see merchantApplication.service.js) — left as-is pending its own confirmation pass.
//
// Deliberately NO listStoresByMerchant()-style method: Surfboard's docs don't confirm a
// list-stores-by-merchant endpoint, and inventing one would violate the explicit "do not invent
// Surfboard endpoints or payloads" instruction for this phase (see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-023). `GET /stores` is served from SurfPOS's own
// `storeReferences/{uid}` registry instead — see modules/store/store.service.js.

const SurfboardBaseClient = require('./client/surfboardClient.base');

const CREATE_STORE_PATH = '/stores';
// Confirmed Fetch/Update Store Details path (see class doc comment above) — identical for both.
const storePath = (partnerId, merchantId, storeId) =>
  `/partners/${partnerId}/merchants/${merchantId}/stores/${storeId}`;

class SurfboardStoreClient extends SurfboardBaseClient {
  /**
   * @param {object} wirePayload — already in Surfboard's wire format (see store.mapper.js#toWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async createStore(wirePayload) {
    const { data } = await this.request({ method: 'POST', path: CREATE_STORE_PATH, body: wirePayload });
    return data;
  }

  /**
   * @param {string} merchantId
   * @param {string} storeId
   * @returns {Promise<object>} raw Surfboard response body
   */
  async getStore(merchantId, storeId) {
    const { data } = await this.request({
      method: 'GET',
      path: storePath(this.config.partnerId, merchantId, storeId),
      headers: { 'MERCHANT-ID': merchantId },
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * @param {string} merchantId
   * @param {string} storeId
   * @param {object} wirePayload — already in Surfboard's wire format (see store.mapper.js#toUpdateWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async updateStore(merchantId, storeId, wirePayload) {
    const { data } = await this.request({
      method: 'PUT',
      path: storePath(this.config.partnerId, merchantId, storeId),
      headers: { 'MERCHANT-ID': merchantId },
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }
}

module.exports = new SurfboardStoreClient();
module.exports.SurfboardStoreClient = SurfboardStoreClient;
