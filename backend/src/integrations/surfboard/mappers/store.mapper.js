'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for Store Capabilities —
// see docs/21_BACKEND_GUIDELINES.md § 6. Isolates the still-unconfirmed Surfboard field names
// (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) to this one file.

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
   * @param {object} raw Surfboard's Store GET/POST/PATCH response body
   * @returns {{ id: string, merchantId: string, name: string, address: object, capabilities: object|null, status: string|null }}
   */
  toDomain(raw = {}) {
    return {
      id: raw.store_id ?? raw.id ?? null,
      merchantId: raw.merchant_id ?? null,
      name: raw.name ?? null,
      address: raw.address ?? null,
      capabilities: raw.capabilities ?? null,
      status: raw.status ?? null,
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
