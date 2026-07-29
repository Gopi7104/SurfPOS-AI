'use strict';

// Merchant application submission + tracking (Roadmap Phase 4, docs/22_DEVELOPMENT_ROADMAP.md).
// Coordinates a live Surfboard Merchant Creation call with Firebase-owned application-tracking
// metadata — never a duplicated copy of the Merchant object itself (docs/20_DOMAIN_MODEL.md § 1).
// Store creation, `users/{uid}.merchantId` linkage, and Merchant profile proxy endpoints are all
// out of scope here — see docs/08_ARCHITECTURE_DECISIONS.md § ADR-021.

const { MESSAGES } = require('../../constants');
const { ConflictError, NotFoundError } = require('../../utils/errors');
const defaultMerchantClient = require('../../integrations/surfboard/merchant.client');
const defaultMapper = require('../../integrations/surfboard/mappers/merchant.mapper');
const defaultMerchantApplicationRepository = require('./merchantApplication.repository');

/**
 * @param {{ merchantClient?: object, mapper?: object, merchantApplicationRepository?: object }} [deps]
 */
function createMerchantApplicationService({
  merchantClient = defaultMerchantClient,
  mapper = defaultMapper,
  merchantApplicationRepository = defaultMerchantApplicationRepository,
} = {}) {
  /**
   * @param {string} uid
   * @param {{ businessName: string, businessType: string, contactEmail: string, contactPhone: string, address: object }} input
   */
  async function submitApplication(uid, input) {
    const existing = await merchantApplicationRepository.get(uid);
    if (existing) {
      throw new ConflictError(MESSAGES.MERCHANT_APPLICATION_ALREADY_EXISTS);
    }

    const wirePayload = mapper.toWire(input);
    const surfboardResponse = await merchantClient.createMerchant(wirePayload);
    const domain = mapper.toDomain(surfboardResponse);

    const now = Date.now();
    const application = {
      applicationId: domain.applicationId || uid,
      merchantId: domain.merchantId,
      applicationStatus: domain.applicationStatus,
      applicationUrl: domain.applicationUrl,
      submittedAt: now,
      updatedAt: now,
    };

    return merchantApplicationRepository.create(uid, application);
  }

  /**
   * @param {string} uid
   * @param {string} applicationId
   */
  async function getApplication(uid, applicationId) {
    const application = await merchantApplicationRepository.get(uid);
    if (!application || application.applicationId !== applicationId) {
      throw new NotFoundError(MESSAGES.MERCHANT_APPLICATION_NOT_FOUND);
    }
    return application;
  }

  /** @param {string} uid */
  async function listApplications(uid) {
    const application = await merchantApplicationRepository.get(uid);
    return application ? [application] : [];
  }

  return { submitApplication, getApplication, listApplications };
}

module.exports = createMerchantApplicationService();
module.exports.createMerchantApplicationService = createMerchantApplicationService;
