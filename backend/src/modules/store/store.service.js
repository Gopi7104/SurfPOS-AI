'use strict';

// Store Capabilities (Roadmap Phase 6, docs/22_DEVELOPMENT_ROADMAP.md) — creates/fetches/updates
// the live Surfboard Store for the authenticated caller's own merchant. Never persists the full
// Store object in Firebase (docs/20_DOMAIN_MODEL.md § 1) — only a minimal local registry of which
// storeIds SurfPOS created (docs/08_ARCHITECTURE_DECISIONS.md § ADR-023). Inventory, Billing,
// Payments, Device Management, Branding, Analytics, and AI are all out of scope here.

const { MESSAGES } = require('../../constants');
const { NotFoundError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultStoreClient = require('../../integrations/surfboard/store.client');
const defaultMapper = require('../../integrations/surfboard/mappers/store.mapper');
const defaultStoreRepository = require('./store.repository');
const defaultMerchantService = require('../merchant/merchant.service');

/**
 * @param {{ storeClient?: object, mapper?: object, storeRepository?: object, merchantService?: object, logger?: object }} [deps]
 */
function createStoreService({
  storeClient = defaultStoreClient,
  mapper = defaultMapper,
  storeRepository = defaultStoreRepository,
  merchantService = defaultMerchantService,
  logger = defaultLogger,
} = {}) {
  async function assertOwnsStore(uid, storeId) {
    const owned = await storeRepository.hasReference(uid, storeId);
    if (!owned) {
      throw new NotFoundError(MESSAGES.STORE_NOT_FOUND);
    }
  }

  /**
   * @param {string} uid
   * @param {{ name: string, address: object }} input
   */
  async function createStore(uid, input) {
    const merchantId = await merchantService.getMerchantId(uid);
    const wirePayload = mapper.toWire({ merchantId, ...input });
    const surfboardResponse = await storeClient.createStore(wirePayload);
    const store = mapper.toDomain(surfboardResponse);

    await storeRepository.addReference(uid, store.id, { merchantId });
    logger.info({ uid, merchantId, storeId: store.id }, 'Created store');

    return store;
  }

  /**
   * @param {string} uid
   * @param {string} storeId
   */
  async function getStore(uid, storeId) {
    await assertOwnsStore(uid, storeId);
    const merchantId = await merchantService.getMerchantId(uid);
    const surfboardResponse = await storeClient.getStore(merchantId, storeId);
    return mapper.toDomain(surfboardResponse);
  }

  /**
   * @param {string} uid
   * @param {string} storeId
   * @param {object} patch partial Store fields to update
   */
  async function updateStore(uid, storeId, patch) {
    await assertOwnsStore(uid, storeId);
    const merchantId = await merchantService.getMerchantId(uid);
    const wirePayload = mapper.toUpdateWire(patch);
    const surfboardResponse = await storeClient.updateStore(merchantId, storeId, wirePayload);
    const store = mapper.toDomain(surfboardResponse);

    logger.info({ uid, storeId }, 'Updated store');

    return store;
  }

  /** @param {string} uid */
  async function listStores(uid) {
    const storeIds = await storeRepository.listReferences(uid);
    if (storeIds.length === 0) {
      return [];
    }
    const merchantId = await merchantService.getMerchantId(uid);
    const stores = await Promise.all(
      storeIds.map((storeId) => storeClient.getStore(merchantId, storeId).then(mapper.toDomain)),
    );
    return stores;
  }

  /**
   * Verifies the caller's registry lists this storeId — exposed so other modules (e.g.
   * `modules/inventory/`) can depend on this Service instead of reaching into
   * `modules/store/store.repository.js` directly, per the cross-module rule
   * (docs/21_BACKEND_GUIDELINES.md § 8). Throws NotFoundError if not owned.
   * @param {string} uid
   * @param {string} storeId
   */
  async function verifyStoreOwnership(uid, storeId) {
    return assertOwnsStore(uid, storeId);
  }

  /**
   * Returns the caller's first registered storeId, or null if they have none yet — a cheap,
   * registry-only lookup (no live Surfboard call, unlike [listStores]) so callers that only need
   * *which* store to scope something to (e.g. `modules/inventory/`'s stock hydration, when no
   * explicit `storeId` was requested) don't pay for a full Store fetch just to pick a default.
   * @param {string} uid
   */
  async function getPrimaryStoreId(uid) {
    const storeIds = await storeRepository.listReferences(uid);
    return storeIds[0] ?? null;
  }

  /**
   * Registers a storeId this caller didn't create via `createStore()` here directly — Surfboard's
   * Create Merchant call can create a Store as a side effect of onboarding (`controlFields.store`,
   * see merchantApplication.service.js), so that storeId would otherwise never appear in this
   * caller's `storeReferences/{uid}` registry and every `GET /stores/:storeId` call for it would
   * incorrectly 404. Idempotent (`addReference` is a plain `.set()`), safe to call every time the
   * onboarding flow observes a storeId. Exposed for `modules/merchant/` to depend on instead of
   * reaching into `store.repository.js` directly, per the cross-module rule.
   * @param {string} uid
   * @param {{ storeId: string, merchantId: string }} reference
   */
  async function registerDiscoveredStore(uid, { storeId, merchantId }) {
    await storeRepository.addReference(uid, storeId, { merchantId });
    logger.info({ uid, merchantId, storeId }, 'Registered store discovered via merchant onboarding');
  }

  return {
    createStore,
    getStore,
    updateStore,
    listStores,
    verifyStoreOwnership,
    registerDiscoveredStore,
    getPrimaryStoreId,
  };
}

module.exports = createStoreService();
module.exports.createStoreService = createStoreService;
