'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for Merchant Onboarding —
// see docs/21_BACKEND_GUIDELINES.md § 6. Confirmed against the real Surfboard docs (Create
// Merchant, Check Application Status, Fetch/Update Merchant Details) — see
// docs/08_ARCHITECTURE_DECISIONS.md § ADR-025. Every Surfboard response body is the
// `{ status, data, message }` envelope every endpoint in this family shares; `raw.data` is where
// the actual payload lives.

const BaseMapper = require('./baseMapper');

/** @param {{ addressLine1: string, addressLine2?: string, careOf?: string, city: string, countryCode: string, postalCode: string }} address */
function addressToWire(address) {
  return {
    ...(address.careOf && { careOf: address.careOf }),
    addressLine1: address.addressLine1,
    ...(address.addressLine2 && { addressLine2: address.addressLine2 }),
    city: address.city,
    countryCode: address.countryCode,
    postalCode: address.postalCode,
  };
}

class MerchantMapper extends BaseMapper {
  /**
   * @param {{
   *   country: string,
   *   organisation: {
   *     corporateId: string, legalName?: string, mccCode?: string, email?: string,
   *     phoneNumber?: { code: string, number: string },
   *     address: { addressLine1: string, addressLine2?: string, careOf?: string, city: string, countryCode: string, postalCode: string },
   *   },
   *   store: {
   *     name: string, email: string, phoneNumber: { code: string, number: string },
   *     address: { addressLine1: string, addressLine2?: string, careOf?: string, city: string, countryCode: string, postalCode: string },
   *   },
   * }} domain
   * @returns {object} Surfboard's Create Merchant request body
   */
  toWire(domain) {
    const { organisation, store } = domain;

    return {
      country: domain.country,
      organisation: {
        corporateId: organisation.corporateId,
        ...(organisation.legalName && { legalName: organisation.legalName }),
        ...(organisation.mccCode && { mccCode: organisation.mccCode }),
        address: addressToWire(organisation.address),
        ...(organisation.phoneNumber && { phoneNumber: organisation.phoneNumber }),
        ...(organisation.email && { email: organisation.email }),
      },
      controlFields: {
        generateShortLink: true,
        store: {
          name: store.name,
          email: store.email,
          phoneNumber: store.phoneNumber,
          address: addressToWire(store.address),
        },
      },
    };
  }

  /**
   * Normalizes the Create Merchant response. The create call itself never returns a status field
   * — a freshly created application is always `APPLICATION_INITIATED` (confirmed from docs); the
   * real current status is only ever known via `toApplicationStatusDomain()`.
   * @param {{ data?: { applicationId?: string, webKybUrl?: string, merchantId?: string, storeId?: string, shortLinkUrl?: string } }} raw
   * @returns {{ applicationId: string|null, merchantId: string|null, storeId: string|null, applicationStatus: string, applicationUrl: string|null, shortLinkUrl: string|null }}
   */
  toDomain(raw = {}) {
    const data = raw.data ?? {};
    return {
      applicationId: data.applicationId ?? null,
      merchantId: data.merchantId ?? null,
      storeId: data.storeId ?? null,
      applicationStatus: 'APPLICATION_INITIATED',
      applicationUrl: data.webKybUrl ?? null,
      shortLinkUrl: data.shortLinkUrl ?? null,
    };
  }

  /**
   * Normalizes the Check Application Status response — distinct from `toDomain()` above, which
   * only normalizes the narrower Create Merchant response.
   * @param {{ data?: { applicationId?: string, webKybUrl?: string, applicationStatus?: string, merchantId?: string, storeId?: string, onlineOnboardingStatus?: string } }} raw
   * @returns {{ applicationId: string|null, applicationStatus: string|null, merchantId: string|null, storeId: string|null, applicationUrl: string|null, onlineOnboardingStatus: string|null }}
   */
  toApplicationStatusDomain(raw = {}) {
    const data = raw.data ?? {};
    return {
      applicationId: data.applicationId ?? null,
      applicationStatus: data.applicationStatus ?? null,
      merchantId: data.merchantId ?? null,
      storeId: data.storeId ?? null,
      applicationUrl: data.webKybUrl ?? null,
      onlineOnboardingStatus: data.onlineOnboardingStatus ?? null,
    };
  }

  /**
   * Normalizes a Fetch Merchant Details response into the full domain Merchant shape
   * (docs/20_DOMAIN_MODEL.md § 2.1) — Phase 5. Field names confirmed against
   * `merchants-fetch-merchant-details.md` — note the response is flat (`merchantName`,
   * `companyId`, `email`, `phoneNumber` as a plain string), unlike Create Merchant's nested
   * `organisation` request shape.
   * @param {object} raw
   * @returns {{ id: string|null, name: string|null, companyId: string|null, email: string|null, phoneNumber: string|null, logoUrl: string|null, mccCode: string|null, countryCode: string|null, address: object|null }}
   */
  toMerchantProfile(raw = {}) {
    const data = raw.data ?? {};
    return {
      id: data.merchantId ?? null,
      name: data.merchantName ?? null,
      companyId: data.companyId ?? null,
      email: data.email ?? null,
      phoneNumber: data.phoneNumber ?? null,
      logoUrl: data.merchantLogoUrl ?? null,
      mccCode: data.mccCode === null || data.mccCode === undefined ? null : String(data.mccCode),
      countryCode: data.countryCode ?? null,
      address: data.address ?? null,
    };
  }

  /**
   * @param {{ email?: string, logoUrl?: string, phoneNumber?: { code: string|number, number: string } }} domain partial update
   * @returns {object} Surfboard's Update Merchant Details request body — only the provided fields
   */
  toMerchantUpdateWire(domain = {}) {
    const wire = {};
    if (domain.email !== undefined) wire.email = domain.email;
    if (domain.logoUrl !== undefined) wire.merchantLogoUrl = domain.logoUrl;
    if (domain.phoneNumber !== undefined) wire.phoneNumber = domain.phoneNumber;
    return wire;
  }
}

module.exports = new MerchantMapper();
module.exports.MerchantMapper = MerchantMapper;
