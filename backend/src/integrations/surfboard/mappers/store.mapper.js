'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for Store Capabilities —
// see docs/21_BACKEND_GUIDELINES.md § 6. `toDomain()`/`toUpdateWire()` are confirmed against the
// real bundled docs (`api-md/stores-fetch-store-details.md`, `api-md/stores-update-store-details.md`
// — same source ADR-025/ADR-026 used for Merchant): both share the camelCase `storeId`/`merchantId`
// response shape; Update's request body is flatter than Create's (`address` is a plain string —
// address line 1 — plus separate `careOf`/`city`, not the nested object Fetch/Create return).
// `toWire()` (Create Store) remains unconfirmed (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) —
// still never called from any live flow (Surfboard creates a Store as a side effect of Create
// Merchant instead, see merchantApplication.service.js).

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
   * @param {{ data?: object }} raw Surfboard's `{status, data, message}` Store GET/POST/PUT envelope
   * @returns {{ id: string, merchantId: string, name: string, address: object, capabilities: object|null, status: string|null, onlineInfo: object|null }}
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
      // Only present once a store has been converted to an "online store" — see
      // api-md/stores-fetch-store-details.md: "only returned if online store information is
      // available." null here is exactly what payment.service.js#ensureStoreOnlineInfo checks.
      onlineInfo: data.onlineInfo ?? null,
    };
  }

  /**
   * @param {{ name?: string, email?: string, phoneNumber?: { code: number, number: string }, addressLine1?: string, careOf?: string, city?: string, onlineInfo?: { merchantWebshopURL: string, paymentPageHostURL?: string, termsAndConditionsURL: string, privacyPolicyURL: string } }} domain partial update
   * @returns {object} Surfboard's Update Store Details request body (PUT) — only the provided fields
   */
  toUpdateWire(domain = {}) {
    const wire = {};
    if (domain.name !== undefined) wire.storeName = domain.name;
    if (domain.email !== undefined) wire.email = domain.email;
    if (domain.phoneNumber !== undefined) wire.phoneNumber = domain.phoneNumber;
    if (domain.addressLine1 !== undefined) wire.address = domain.addressLine1;
    if (domain.careOf !== undefined) wire.careOf = domain.careOf;
    if (domain.city !== undefined) wire.city = domain.city;
    if (domain.onlineInfo !== undefined) wire.onlineInfo = domain.onlineInfo;
    return wire;
  }
}

module.exports = new StoreMapper();
module.exports.StoreMapper = StoreMapper;
