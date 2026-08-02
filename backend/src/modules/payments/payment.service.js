'use strict';

// Payment Integration (Roadmap Phase 4, docs/22_DEVELOPMENT_ROADMAP.md) — Checkout's Surfboard
// order/payment orchestration. `merchantId`/store ownership are resolved via cross-module Service
// calls (docs/21_BACKEND_GUIDELINES.md § 8), same pattern as modules/inventory/inventory.service.js.
//
// SurfPOS has never registered a physical Surfboard card terminal (device.client.js is still a
// placeholder, and no Store record has ever carried a terminalId) — Checkout instead registers a
// software-only *online* terminal per store (`onlineTerminalMode: "PaymentPage"`, see
// api-md/terminals-register-online-terminal.md) the first time that store takes a payment, and
// reuses it for every order after. The customer completes payment on Surfboard's own hosted page
// (via the `paymentUrl`/`qr` Initiate a Payment returns) while this app polls order status —
// there is no "Card Inserted"/terminal-hardware state to observe, only the order/payment status
// enum Surfboard itself exposes; the Flutter app's own PaymentController maps those enum values to
// its PaymentPhase UI states.
//
// Per docs/15_SURFBOARD_INTEGRATION.md § 5.1: never create a payment for a client-submitted total
// directly. `createCheckout()` resolves every line item through
// `modules/billing/billing.service.js#resolveCheckoutItems()`, which re-fetches each product's
// real price/tax/discount from Inventory — the client only ever sends `{ productId, quantity }`,
// never a price, tax rate, discount, or total.

const { MESSAGES } = require('../../constants');
const { NotFoundError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultConfig = require('../../config');
const defaultPaymentClient = require('../../integrations/surfboard/payment.client');
const defaultMapper = require('../../integrations/surfboard/mappers/payment.mapper');
const defaultPaymentRepository = require('./payment.repository');
const defaultMerchantService = require('../merchant/merchant.service');
const defaultStoreService = require('../store/store.service');
const defaultBillingService = require('../billing/billing.service');

/**
 * @param {{ paymentClient?: object, mapper?: object, paymentRepository?: object, merchantService?: object, storeService?: object, billingService?: object, config?: object, logger?: object }} [deps]
 */
function createPaymentService({
  paymentClient = defaultPaymentClient,
  mapper = defaultMapper,
  paymentRepository = defaultPaymentRepository,
  merchantService = defaultMerchantService,
  storeService = defaultStoreService,
  billingService = defaultBillingService,
  config = defaultConfig,
  logger = defaultLogger,
} = {}) {
  /**
   * @param {string} uid
   * @param {string} [requestedStoreId]
   * @returns {Promise<string>} throws NotFoundError if the caller has no store yet
   */
  async function resolveStoreId(uid, requestedStoreId) {
    if (requestedStoreId) {
      await storeService.verifyStoreOwnership(uid, requestedStoreId);
      return requestedStoreId;
    }
    const storeId = await storeService.getPrimaryStoreId(uid);
    if (!storeId) {
      throw new NotFoundError(MESSAGES.NO_STORE_AVAILABLE);
    }
    return storeId;
  }

  /**
   * A store must be converted to an "online store" before it can accept payments through a
   * PaymentPage-mode online terminal — see api-md/stores-update-store-details.md: `onlineInfo`
   * (merchantWebshopURL/termsAndConditionsURL/privacyPolicyURL) is required, and Surfboard's own
   * `POST .../online-terminals` rejects a store that's missing it with
   * `TM_0029: Onboarding is not completed for the store` (confirmed live against the real sandbox
   * API — see docs/22_DEVELOPMENT_ROADMAP.md's Payment Integration troubleshooting notes). Setting
   * `onlineInfo` is possible only ONCE per store (Surfboard's own restriction), so this checks the
   * live store first and only calls Update Store Details if it's genuinely still unset.
   * @param {string} uid
   * @param {string} storeId
   */
  async function ensureStoreOnlineInfo(uid, storeId) {
    const store = await storeService.getStore(uid, storeId);
    if (store.onlineInfo) return;

    await storeService.updateStore(uid, storeId, {
      onlineInfo: {
        merchantWebshopURL: config.surfboard.onlineStore.webshopUrl,
        termsAndConditionsURL: config.surfboard.onlineStore.termsUrl,
        privacyPolicyURL: config.surfboard.onlineStore.privacyUrl,
      },
    });
    logger.info({ uid, storeId }, 'Converted store to an online store (set onlineInfo)');
  }

  /**
   * Registers a `PaymentPage` online terminal for this store the first time it's needed, and
   * caches the result — see this file's header comment.
   * @param {string} uid
   * @param {string} merchantId
   * @param {string} storeId
   * @returns {Promise<string>} terminalId
   */
  async function getOrCreateTerminalId(uid, merchantId, storeId) {
    const cached = await paymentRepository.getTerminalId(storeId);
    if (cached) return cached;

    await ensureStoreOnlineInfo(uid, storeId);

    const raw = await paymentClient.registerOnlineTerminal(
      merchantId,
      storeId,
      mapper.toRegisterTerminalWire(),
    );
    const { terminalId } = mapper.toTerminalDomain(raw);
    await paymentRepository.setTerminalId(storeId, terminalId);
    logger.info({ storeId, terminalId }, 'Registered online terminal');
    return terminalId;
  }

  /**
   * Builds the redirect-back-into-app + webhook URLs to hand Surfboard, or `null` when this
   * backend has no known public URL — see config/index.js's `PUBLIC_BASE_URL` doc comment for why
   * that's the normal, fully-supported state on a local-LAN dev machine (Checkout still works via
   * status polling either way).
   * @returns {{ success: string, failure: string, callBackUrl: string }|null}
   */
  function buildRedirectUrls() {
    if (!config.publicBaseUrl) return null;
    const base = config.publicBaseUrl.replace(/\/$/, '');
    return {
      success: `${base}/payments/redirect/success`,
      failure: `${base}/payments/redirect/failed`,
      callBackUrl: `${base}/webhooks/surfboard`,
    };
  }

  /**
   * Creates a brand-new order for `items` and returns its hosted payment link — the one and only
   * place `paymentClient.createOrder()` is called, shared by `createCheckout()` (first attempt)
   * and `retryPayment()` (every subsequent attempt against the same cart). For a PaymentPage-mode
   * online terminal, this single call both creates the order and generates its hosted payment link
   * (`paymentPageLink`, see payment.mapper.js#toOrderDomain); confirmed live that a follow-up
   * Initiate a Payment call is unnecessary AND actively broken for this terminal type (`PS_0025`),
   * so this never makes one.
   *
   * `items` is resolved through `billingService.resolveCheckoutItems()` — never trusted as-is —
   * so the caller can only ever specify *which* products and *how many*, never their price/tax/
   * discount (see docs/15_SURFBOARD_INTEGRATION.md § 5.1). Re-resolving on every call (including
   * retries) also means a retry always prices against the current catalog, never a stale snapshot.
   * @param {string} uid
   * @param {string} merchantId
   * @param {string} storeId
   * @param {Array<{ productId: string, quantity: number }>} items
   * @param {string} referencePrefix distinguishes a retry's referenceId from the original attempt's
   */
  async function createOrderAndLink(uid, merchantId, storeId, items, referencePrefix) {
    const terminalId = await getOrCreateTerminalId(uid, merchantId, storeId);
    const checkoutSummary = await billingService.resolveCheckoutItems(uid, storeId, items);

    const referenceId = `${referencePrefix}-${uid}-${Date.now()}`;
    const orderWire = mapper.toOrderWire({
      terminalId,
      referenceId,
      items: checkoutSummary.items,
      redirectUrls: buildRedirectUrls(),
    });
    const orderRaw = await paymentClient.createOrder(merchantId, orderWire);
    const { orderId, paymentUrl } = mapper.toOrderDomain(orderRaw);

    if (paymentUrl) {
      await paymentRepository.setPaymentUrl(orderId, paymentUrl);
    }
    await paymentRepository.setCheckoutItems(orderId, items);

    return {
      orderId,
      storeId,
      subtotal: checkoutSummary.subtotal,
      discountTotal: checkoutSummary.discountTotal,
      taxTotal: checkoutSummary.taxTotal,
      amount: checkoutSummary.grandTotal,
      paymentUrl,
      // No paymentId yet — Surfboard's own `payments[]` for this order stays empty (per a live
      // Fetch Order Status check) until the customer actually opens paymentUrl and acts on it.
      paymentId: null,
    };
  }

  /**
   * @param {string} uid
   * @param {{ storeId?: string, items: Array<{ productId: string, quantity: number }> }} input
   */
  async function createCheckout(uid, { storeId: requestedStoreId, items }) {
    const merchantId = await merchantService.getMerchantId(uid);
    const storeId = await resolveStoreId(uid, requestedStoreId);
    const result = await createOrderAndLink(uid, merchantId, storeId, items, 'checkout');
    logger.info({ uid, storeId, orderId: result.orderId }, 'Created checkout');
    return result;
  }

  /**
   * Creates a genuinely NEW order (and its own fresh hosted payment link) for the same cart the
   * original order was created for — it never reopens the previous order's link.
   *
   * Surfboard's hosted Payment Page is a one-shot session scoped to the order it was generated
   * for: once the customer's browser reaches it and the attempt concludes (success, decline, or
   * cancel), that specific link is done — reopening it renders Surfboard's own "Invalid or Expired
   * Link" page, independent of whether the *order* itself is still PENDING and technically
   * retryable per web-guides/create-an-order.md's payment-status table. There is also no Surfboard
   * endpoint to regenerate/re-fetch a PaymentPage link for an existing order (confirmed live: Fetch
   * Order Status's response never includes one) — Create Order is the only documented way to
   * obtain one. So "retry" here means: same cart, brand-new order, brand-new link — never re-serve
   * `payment.repository.js`'s cached `orderPaymentUrls/{orderId}` for the OLD orderId.
   * @param {string} uid
   * @param {string} orderId the order the failed/cancelled/expired attempt was made against
   * @param {string} storeId
   * @returns {Promise<object>} same shape as createCheckout()'s return — including a NEW `orderId`
   *   the caller must switch to (status polling against the old orderId would never resolve)
   */
  async function retryPayment(uid, orderId, storeId) {
    await resolveStoreId(uid, storeId);

    const status = await getCheckoutStatus(uid, orderId);
    // A completed (full or partial) order already has a real Payment against it — retrying must
    // never risk a second charge for the same sale. Anything else (PENDING, PAYMENT_CANCELLED,
    // PAYMENT_FAILED) is safe to superseded with a brand-new order.
    if (status.orderStatus === 'PAYMENT_COMPLETED' || status.orderStatus === 'PARTIAL_PAYMENT_COMPLETED') {
      throw new NotFoundError(MESSAGES.ORDER_NOT_FOUND);
    }

    const items = await paymentRepository.getCheckoutItems(orderId);
    if (!items) {
      throw new NotFoundError(MESSAGES.ORDER_RETRY_CONTEXT_NOT_FOUND);
    }

    const merchantId = await merchantService.getMerchantId(uid);
    const result = await createOrderAndLink(uid, merchantId, storeId, items, 'checkout-retry');
    logger.info(
      { uid, previousOrderId: orderId, orderId: result.orderId },
      'Retried payment — created a new order with a fresh payment link',
    );
    return result;
  }

  /**
   * @param {string} uid
   * @param {string} orderId
   */
  async function getCheckoutStatus(uid, orderId) {
    const { paymentTrace } = require('../../utils/paymentTrace'); // TEMPORARY — see paymentTrace.js
    paymentTrace(10, 'entered', { orderId });

    // A terminal outcome cached from Surfboard's webhook (see webhook.controller.js) always wins
    // over a fresh Fetch Order Status call — confirmed live that the latter can lag the actual
    // completed payment by anywhere from tens of seconds to several minutes on the sandbox, well
    // past how long the Flutter app polls for. Skipping the Surfboard call entirely here is also
    // strictly faster for the already-common case where the webhook beat this call to it.
    const cached = await paymentRepository.getWebhookStatus(orderId);
    if (cached) {
      paymentTrace(11, 'result', {
        orderId,
        source: 'webhook-cache',
        orderStatus: cached.orderStatus,
        paymentStatus: cached.paymentStatus,
        paymentId: cached.paymentId,
        transactionId: cached.transactionId,
      });
      return cached;
    }

    const merchantId = await merchantService.getMerchantId(uid);
    const raw = await paymentClient.getOrderStatus(merchantId, orderId);
    paymentTrace(10, 'exited', { orderId, rawSurfboardResponse: raw });
    const domain = mapper.toOrderStatusDomain(raw);
    paymentTrace(11, 'result', {
      orderId,
      source: 'poll',
      orderStatus: domain.orderStatus,
      paymentStatus: domain.paymentStatus,
      paymentId: domain.paymentId,
      transactionId: domain.transactionId,
    });
    return domain;
  }

  /**
   * @param {string} uid
   * @param {string} paymentId
   */
  async function cancelCheckout(uid, paymentId) {
    const merchantId = await merchantService.getMerchantId(uid);
    const raw = await paymentClient.cancelPayment(merchantId, paymentId);
    const result = mapper.toCancelDomain(raw);

    logger.info({ uid, paymentId }, 'Cancelled payment');
    return result;
  }

  return { createCheckout, retryPayment, getCheckoutStatus, cancelCheckout };
}

module.exports = createPaymentService();
module.exports.createPaymentService = createPaymentService;
