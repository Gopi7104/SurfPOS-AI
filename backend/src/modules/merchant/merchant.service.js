'use strict';

// Merchant profile functions (Roadmap Phase 5, docs/22_DEVELOPMENT_ROADMAP.md) — fetches/updates
// the live Surfboard Merchant profile for the authenticated caller's own merchant reference.
// Never persists the full Merchant object in Firebase (docs/20_DOMAIN_MODEL.md § 1); only ever
// refreshes the minimal cached `applicationStatus` snapshot already tracked on
// `merchantApplications/{uid}` (Phase 4). Store Management, Inventory, Billing, Payments, Device
// Management, Branding, and AI are all out of scope here.

const { MESSAGES } = require('../../constants');
const { NotFoundError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultMerchantClient = require('../../integrations/surfboard/merchant.client');
const defaultMapper = require('../../integrations/surfboard/mappers/merchant.mapper');
const defaultMerchantRepository = require('./merchant.repository');

/**
 * @param {{ merchantClient?: object, mapper?: object, merchantRepository?: object, logger?: object }} [deps]
 */
function createMerchantService({
  merchantClient = defaultMerchantClient,
  mapper = defaultMapper,
  merchantRepository = defaultMerchantRepository,
  logger = defaultLogger,
} = {}) {
  async function resolveMerchantId(uid) {
    const reference = await merchantRepository.getMerchantReference(uid);
    if (!reference) {
      throw new NotFoundError(MESSAGES.MERCHANT_REFERENCE_NOT_FOUND);
    }
    return reference.merchantId;
  }

  /** @param {string} uid */
  async function getMerchantDetails(uid) {
    const merchantId = await resolveMerchantId(uid);
    const surfboardResponse = await merchantClient.getMerchant(merchantId);
    const merchant = mapper.toMerchantProfile(surfboardResponse);

    await merchantRepository.cacheMerchantMetadata(uid, { applicationStatus: merchant.status });
    logger.info({ uid, merchantId }, 'Fetched merchant profile');

    return merchant;
  }

  /**
   * @param {string} uid
   * @param {object} patch partial Merchant fields to update
   */
  async function updateMerchantDetails(uid, patch) {
    const merchantId = await resolveMerchantId(uid);
    const wirePayload = mapper.toMerchantUpdateWire(patch);
    const surfboardResponse = await merchantClient.updateMerchant(merchantId, wirePayload);
    const merchant = mapper.toMerchantProfile(surfboardResponse);

    await merchantRepository.cacheMerchantMetadata(uid, { applicationStatus: merchant.status });
    logger.info({ uid, merchantId }, 'Updated merchant profile');

    return merchant;
  }

  /** @param {string} uid */
  async function getMerchantStatus(uid) {
    const merchant = await getMerchantDetails(uid);
    return { merchantId: merchant.id, status: merchant.status };
  }

  /**
   * Resolves the caller's Surfboard merchantId reference — exposed so other modules (e.g.
   * `modules/store/`) can depend on this Service instead of reaching into
   * `modules/merchant/merchant.repository.js` directly, per the cross-module rule
   * (docs/21_BACKEND_GUIDELINES.md § 8).
   * @param {string} uid
   * @returns {Promise<string>} merchantId — throws NotFoundError if none is assigned yet
   */
  async function getMerchantId(uid) {
    return resolveMerchantId(uid);
  }

  return { getMerchantDetails, updateMerchantDetails, getMerchantStatus, getMerchantId };
}

module.exports = createMerchantService();
module.exports.createMerchantService = createMerchantService;
