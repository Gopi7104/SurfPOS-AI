'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for Store Capabilities —
// see docs/21_BACKEND_GUIDELINES.md § 6. `toDomain()` is confirmed against the real Fetch/Create
// Store Details docs (both share the same camelCase `storeId`/`merchantId` response shape — see
// store.client.js's header comment); `toWire()`/`toUpdateWire()` remain unconfirmed
// (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) since createStore()/updateStore() aren't called
// from any live flow yet.

const BaseMapper = require('./baseMapper');

class StoreMapper extends BaseMapper {
  /**
   * @param {{ merchantId: string, name: string, address: object }} domain
   * @returns {object} Surfboard's Store Creation request body
   */
  toWire(domain) {
    return {
      merchant_id: domain.merchantId,
      name: domain.name,
      address: domain.address,
    };
  }

  /**
   * @param {{ data?: object }} raw Surfboard's `{status, data, message}` Store GET/POST/PATCH envelope
   * @returns {{ id: string, merchantId: string, name: string, address: object, capabilities: object|null, status: string|null }}
   */
  toDomain(raw = {}) {
    const data = raw.data ?? {};
    return {
      id: data.storeId ?? null,
      merchantId: data.merchantId ?? null,
      name: data.name ?? null,
      address: data.address ?? null,
      capabilities: data.capabilities ?? null,
      status: data.status ?? null,
    };
  }

  /**
   * @param {{ name?: string, address?: object }} domain partial update
   * @returns {object} Surfboard's Store PATCH request body — only the provided fields
   */
  toUpdateWire(domain = {}) {
    const wire = {};
    if (domain.name !== undefined) wire.name = domain.name;
    if (domain.address !== undefined) wire.address = domain.address;
    return wire;
  }
}

module.exports = new StoreMapper();
module.exports.StoreMapper = StoreMapper;
