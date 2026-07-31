'use strict';

// Merchant application submission + tracking (Roadmap Phase 4, docs/22_DEVELOPMENT_ROADMAP.md).
// Coordinates a live Surfboard Merchant Creation call with Firebase-owned application-tracking
// metadata — never a duplicated copy of the Merchant object itself (docs/20_DOMAIN_MODEL.md § 1).
// `users/{uid}.merchantId` linkage and Merchant profile proxy endpoints remain out of scope here —
// see docs/08_ARCHITECTURE_DECISIONS.md § ADR-021. Store creation is now in scope (a Store is
// created as part of onboarding via `controlFields.store` — see ADR-025); any storeId Surfboard
// hands back this way is registered into `storeReferences/{uid}` via storeService
// .registerDiscoveredStore() so `GET /stores/:storeId` (used by the Merchant Dashboard) resolves
// it — see registerStoreIfDiscovered() below.

const { MESSAGES } = require('../../constants');
const { NotFoundError } = require('../../utils/errors');
const SurfboardApiError = require('../../integrations/surfboard/errors/surfboardApiError');
const defaultMerchantClient = require('../../integrations/surfboard/merchant.client');
const defaultMapper = require('../../integrations/surfboard/mappers/merchant.mapper');
const defaultMerchantApplicationRepository = require('./merchantApplication.repository');
const defaultStoreService = require('../store/store.service');

// A tracked application only blocks a new submission while Surfboard still considers it live —
// once Surfboard has terminally rejected or expired it, the applicant must be able to start a
// fresh one instead of being locked out forever (docs/22_DEVELOPMENT_ROADMAP.md Phase 4).
const RESUBMITTABLE_STATUSES = ['APPLICATION_REJECTED', 'APPLICATION_EXPIRED'];

/**
 * @param {{ merchantClient?: object, mapper?: object, merchantApplicationRepository?: object, storeService?: object }} [deps]
 */
function createMerchantApplicationService({
  merchantClient = defaultMerchantClient,
  mapper = defaultMapper,
  merchantApplicationRepository = defaultMerchantApplicationRepository,
  storeService = defaultStoreService,
} = {}) {
  /**
   * Surfboard creates a Store as a side effect of Create Merchant (`controlFields.store`) — that
   * storeId is otherwise never registered in `storeReferences/{uid}` (only `storeService
   * .createStore()` does that), which would make every `GET /stores/:storeId` for it 404. Call
   * this anywhere a fresh `merchantId`/`storeId` pair is observed; a no-op until both are known.
   * @param {string} uid
   * @param {{ merchantId: string|null, storeId: string|null }} ids
   */
  async function registerStoreIfDiscovered(uid, { merchantId, storeId }) {
    if (!merchantId || !storeId) {
      return;
    }
    await storeService.registerDiscoveredStore(uid, { merchantId, storeId });
  }

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
      // Never trust the cached Firebase status for this decision — Surfboard is the source of
      // truth, and the cached copy may be long stale by the time the user resubmits.
      const surfboardStatusResponse = await merchantClient.getApplicationStatus(existing.applicationId);
      const statusDomain = mapper.toApplicationStatusDomain(surfboardStatusResponse);
      const liveStatus = statusDomain.applicationStatus ?? existing.applicationStatus ?? null;

      if (!RESUBMITTABLE_STATUSES.includes(liveStatus)) {
        // Still under review, or already approved — either way a second Surfboard application
        // must never be created; hand back the refreshed record of the one that already exists
        // so the caller can route to the Application Status screen or the Merchant Dashboard.
        const mergedMerchantId = statusDomain.merchantId ?? existing.merchantId ?? null;
        const mergedStoreId = statusDomain.storeId ?? existing.storeId ?? null;
        await registerStoreIfDiscovered(uid, { merchantId: mergedMerchantId, storeId: mergedStoreId });

        return merchantApplicationRepository.update(uid, {
          applicationStatus: liveStatus,
          merchantId: mergedMerchantId,
          storeId: mergedStoreId,
          applicationUrl: statusDomain.applicationUrl ?? existing.applicationUrl ?? null,
        });
      }
      // Rejected/expired — fall through and create a new application, replacing the old record.
    }

    const wirePayload = mapper.toWire(input);
    const surfboardResponse = await merchantClient.createMerchant(wirePayload);
    const domain = mapper.toDomain(surfboardResponse);

    if (!domain.applicationId) {
      // Surfboard's own envelope reported success (the base client already rejects a
      // `status: "ERROR"` body — see errors/errorMapper.js#assertSurfboardSuccess), but still
      // omitted an applicationId. Never invent one from `uid` — a fabricated id can never be
      // looked up on Surfboard's side (confirmed: its status endpoint rejects a non-Surfboard id
      // outright), which permanently traps the account behind a phantom application.
      throw new SurfboardApiError('Surfboard did not return an applicationId for this application.', {
        surfboardStatus: surfboardResponse?.status ?? null,
        surfboardMessage: surfboardResponse?.message ?? null,
        body: surfboardResponse ?? null,
      });
    }

    const now = Date.now();
    const application = {
      applicationId: domain.applicationId,
      merchantId: domain.merchantId,
      storeId: domain.storeId,
      applicationStatus: domain.applicationStatus,
      applicationUrl: domain.applicationUrl,
      shortLinkUrl: domain.shortLinkUrl,
      submittedAt: now,
      updatedAt: now,
    };

    await registerStoreIfDiscovered(uid, {
      merchantId: application.merchantId,
      storeId: application.storeId,
    });

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

    const mergedMerchantId = domain.merchantId ?? application.merchantId ?? null;
    const mergedStoreId = domain.storeId ?? application.storeId ?? null;
    await registerStoreIfDiscovered(uid, { merchantId: mergedMerchantId, storeId: mergedStoreId });

    return merchantApplicationRepository.update(uid, {
      applicationStatus: domain.applicationStatus ?? application.applicationStatus ?? null,
      merchantId: mergedMerchantId,
      storeId: mergedStoreId,
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
