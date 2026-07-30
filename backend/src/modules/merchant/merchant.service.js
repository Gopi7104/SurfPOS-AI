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
  async function resolveReference(uid) {
    const reference = await merchantRepository.getMerchantReference(uid);
    if (!reference) {
      throw new NotFoundError(MESSAGES.MERCHANT_REFERENCE_NOT_FOUND);
    }
    return reference;
  }

  async function resolveMerchantId(uid) {
    return (await resolveReference(uid)).merchantId;
  }

  /** @param {string} uid */
  async function getMerchantDetails(uid) {
    const merchantId = await resolveMerchantId(uid);
    const surfboardResponse = await merchantClient.getMerchant(merchantId);
    const merchant = mapper.toMerchantProfile(surfboardResponse);

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
    // Update Merchant Details' own response is just `{ status, message }` — no updated profile
    // (confirmed from docs) — re-fetch to return the current one, same as any other write-then-read.
    await merchantClient.updateMerchant(merchantId, wirePayload);
    const surfboardResponse = await merchantClient.getMerchant(merchantId);
    const merchant = mapper.toMerchantProfile(surfboardResponse);

    logger.info({ uid, merchantId }, 'Updated merchant profile');
    return merchant;
  }

  /**
   * Live application-status check — Fetch Merchant Details has no status field to derive this
   * from (see merchant.repository.js#getMerchantReference's doc comment); the real source is the
   * Check Application Status endpoint, keyed by `applicationId`, not `merchantId`.
   * @param {string} uid
   */
  async function getMerchantStatus(uid) {
    const reference = await resolveReference(uid);
    if (!reference.applicationId) {
      throw new NotFoundError(MESSAGES.MERCHANT_REFERENCE_NOT_FOUND);
    }

    const surfboardResponse = await merchantClient.getApplicationStatus(reference.applicationId);
    const domain = mapper.toApplicationStatusDomain(surfboardResponse);

    await merchantRepository.cacheMerchantMetadata(uid, {
      applicationStatus: domain.applicationStatus,
      ...(domain.merchantId && { merchantId: domain.merchantId }),
    });
    logger.info({ uid, applicationId: reference.applicationId }, 'Refreshed merchant application status');

    return { merchantId: domain.merchantId ?? reference.merchantId, status: domain.applicationStatus };
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
