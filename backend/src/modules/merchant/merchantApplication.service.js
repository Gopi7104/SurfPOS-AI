'use strict';

// Merchant application submission + tracking (Roadmap Phase 4, docs/22_DEVELOPMENT_ROADMAP.md).
// Coordinates a live Surfboard Merchant Creation call with Firebase-owned application-tracking
// metadata — never a duplicated copy of the Merchant object itself (docs/20_DOMAIN_MODEL.md § 1).
// `users/{uid}.merchantId` linkage and Merchant profile proxy endpoints remain out of scope here —
// see docs/08_ARCHITECTURE_DECISIONS.md § ADR-021. Store creation is now in scope (a Store is
// created as part of onboarding via `controlFields.store` — see ADR-025), though no
// `users/{uid}.storeIds` reference is written, same boundary as before.

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
   * @param {{
   *   country: string,
   *   organisation: { corporateId: string, legalName?: string, mccCode?: string, address: object, phoneNumber?: object, email?: string },
   *   store: { name: string, email: string, phoneNumber: object, address: object },
   * }} input
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
      storeId: domain.storeId,
      applicationStatus: domain.applicationStatus,
      applicationUrl: domain.applicationUrl,
      shortLinkUrl: domain.shortLinkUrl,
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

  /**
   * Polls Surfboard's Check Application Status endpoint and refreshes the cached record — the
   * only way to observe progress through the KYB flow (`APPLICATION_INITIATED` ...
   * `MERCHANT_CREATED`) short of standing up a webhook receiver (out of scope here).
   * @param {string} uid
   * @param {string} applicationId
   */
  async function refreshApplicationStatus(uid, applicationId) {
    const application = await getApplication(uid, applicationId);

    const surfboardResponse = await merchantClient.getApplicationStatus(applicationId);
    const domain = mapper.toApplicationStatusDomain(surfboardResponse);

    return merchantApplicationRepository.update(uid, {
      applicationStatus: domain.applicationStatus ?? application.applicationStatus ?? null,
      merchantId: domain.merchantId ?? application.merchantId ?? null,
      storeId: domain.storeId ?? application.storeId ?? null,
      applicationUrl: domain.applicationUrl ?? application.applicationUrl ?? null,
    });
  }

  /** @param {string} uid */
  async function listApplications(uid) {
    const application = await merchantApplicationRepository.get(uid);
    return application ? [application] : [];
  }

  return { submitApplication, getApplication, refreshApplicationStatus, listApplications };
}

module.exports = createMerchantApplicationService();
module.exports.createMerchantApplicationService = createMerchantApplicationService;
