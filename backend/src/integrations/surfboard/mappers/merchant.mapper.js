'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for Merchant Creation —
// see docs/21_BACKEND_GUIDELINES.md § 6. Isolates the still-unconfirmed Surfboard field names
// (docs/08_ARCHITECTURE_DECISIONS.md § ADR-009) to this one file.

const BaseMapper = require('./baseMapper');

class MerchantMapper extends BaseMapper {
  /**
   * @param {{ businessName: string, businessType: string, contactEmail: string, contactPhone: string, address: object }} domain
   * @returns {object} Surfboard's Merchant Creation request body
   */
  toWire(domain) {
    return {
      business_name: domain.businessName,
      business_type: domain.businessType,
      contact_email: domain.contactEmail,
      contact_phone: domain.contactPhone,
      address: domain.address,
    };
  }

  /**
   * @param {object} raw Surfboard's Merchant Creation response body
   * @returns {{ applicationId: string, merchantId: string|null, applicationStatus: string, applicationUrl: string|null }}
   */
  toDomain(raw = {}) {
    return {
      applicationId: raw.application_id ?? raw.merchant_id ?? null,
      merchantId: raw.merchant_id ?? null,
      applicationStatus: raw.status ?? raw.onboarding_status ?? 'pending_verification',
      applicationUrl: raw.onboarding_url ?? raw.application_url ?? null,
    };
  }

  /**
   * Normalizes a Surfboard Merchant GET/PATCH response into the full domain Merchant shape
   * (docs/20_DOMAIN_MODEL.md § 2.1) — distinct from `toDomain()` above, which normalizes the
   * narrower Merchant *Creation* response into an application-tracking shape.
   * @param {object} raw
   * @returns {{ id: string, businessName: string, businessType: string, contactEmail: string, contactPhone: string, address: object, status: string }}
   */
  toMerchantProfile(raw = {}) {
    return {
      id: raw.merchant_id ?? raw.id ?? null,
      businessName: raw.business_name ?? null,
      businessType: raw.business_type ?? null,
      contactEmail: raw.contact_email ?? null,
      contactPhone: raw.contact_phone ?? null,
      address: raw.address ?? null,
      status: raw.status ?? raw.onboarding_status ?? null,
    };
  }

  /**
   * @param {{ businessName?: string, businessType?: string, contactEmail?: string, contactPhone?: string, address?: object }} domain partial update
   * @returns {object} Surfboard's Merchant PATCH request body — only the provided fields
   */
  toMerchantUpdateWire(domain = {}) {
    const wire = {};
    if (domain.businessName !== undefined) wire.business_name = domain.businessName;
    if (domain.businessType !== undefined) wire.business_type = domain.businessType;
    if (domain.contactEmail !== undefined) wire.contact_email = domain.contactEmail;
    if (domain.contactPhone !== undefined) wire.contact_phone = domain.contactPhone;
    if (domain.address !== undefined) wire.address = domain.address;
    return wire;
  }
}

module.exports = new MerchantMapper();
module.exports.MerchantMapper = MerchantMapper;
