'use strict';

// Application-metadata access for Merchant Functions (Roadmap Phase 5) — deliberately does NOT
// call `getDb()` itself. `merchantApplications/{uid}` is already owned end-to-end by
// merchantApplication.repository.js (Phase 4, docs/03_DATABASE_DESIGN.md § 4.11); a second file
// independently calling Firebase for the same node would violate "the only place a given
// Firebase-owned entity is read or written" (docs/21_BACKEND_GUIDELINES.md § 4). This repository
// instead composes that one, exposing a narrower interface scoped to what Merchant Functions
// needs — see docs/08_ARCHITECTURE_DECISIONS.md § ADR-022.

const defaultMerchantApplicationRepository = require('./merchantApplication.repository');

/**
 * @param {{ merchantApplicationRepository?: object }} [deps]
 */
function createMerchantRepository({
  merchantApplicationRepository = defaultMerchantApplicationRepository,
} = {}) {
  /**
   * The caller's Surfboard merchant reference, resolved from their tracked application — not a
   * copy of the Merchant object itself, just the ids + last-cached status. `applicationId` is
   * included so callers can poll the real Check Application Status endpoint (see ADR-025) —
   * Fetch Merchant Details itself has no status field to derive one from (ADR-022's original
   * assumption that it did is now disproven by the confirmed docs).
   * @param {string} uid
   * @returns {Promise<{ merchantId: string, applicationId: string, applicationStatus: string }|null>}
   *   null if no application exists, or one exists but no merchantId has been assigned yet
   */
  async function getMerchantReference(uid) {
    const application = await merchantApplicationRepository.get(uid);
    if (!application || !application.merchantId) {
      return null;
    }
    return {
      merchantId: application.merchantId,
      applicationId: application.applicationId,
      applicationStatus: application.applicationStatus,
    };
  }

  /**
   * Refreshes the minimal cached snapshot after a live Surfboard read/write — never the full
   * Merchant object, only the fields already tracked on `merchantApplications/{uid}`.
   * @param {string} uid
   * @param {{ applicationStatus?: string }} patch
   */
  async function cacheMerchantMetadata(uid, patch) {
    return merchantApplicationRepository.update(uid, { ...patch, updatedAt: Date.now() });
  }

  return { getMerchantReference, cacheMerchantMetadata };
}

module.exports = createMerchantRepository();
module.exports.createMerchantRepository = createMerchantRepository;
