'use strict';

// Surfboard store-capabilities API — see docs/15_SURFBOARD_INTEGRATION.md,
// docs/19_SURFBOARD_WORKFLOWS.md § 2. Wire format is unconfirmed against official Surfboard docs
// (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) — isolated to this file + mappers/store.mapper.js.
//
// Deliberately NO listStoresByMerchant()-style method: Surfboard's docs don't confirm a
// list-stores-by-merchant endpoint, and inventing one would violate the explicit "do not invent
// Surfboard endpoints or payloads" instruction for this phase (see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-023). `GET /stores` is served from SurfPOS's own
// `storeReferences/{uid}` registry instead — see modules/store/store.service.js.

const SurfboardBaseClient = require('./client/surfboardClient.base');

const CREATE_STORE_PATH = '/stores';
const storePath = (storeId) => `/stores/${storeId}`;

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
   * @param {string} storeId
   * @returns {Promise<object>} raw Surfboard response body
   */
  async getStore(storeId) {
    const { data } = await this.request({ method: 'GET', path: storePath(storeId) });
    return data;
  }

  /**
   * @param {string} storeId
   * @param {object} wirePayload — already in Surfboard's wire format (see store.mapper.js#toUpdateWire)
   * @returns {Promise<object>} raw Surfboard response body
   */
  async updateStore(storeId, wirePayload) {
    const { data } = await this.request({ method: 'PATCH', path: storePath(storeId), body: wirePayload });
    return data;
  }
}

module.exports = new SurfboardStoreClient();
module.exports.SurfboardStoreClient = SurfboardStoreClient;
