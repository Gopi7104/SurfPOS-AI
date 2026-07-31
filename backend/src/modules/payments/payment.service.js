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
const defaultPaymentClient = require('../../integrations/surfboard/payment.client');
const defaultMapper = require('../../integrations/surfboard/mappers/payment.mapper');
const defaultPaymentRepository = require('./payment.repository');
const defaultMerchantService = require('../merchant/merchant.service');
const defaultStoreService = require('../store/store.service');
const defaultBillingService = require('../billing/billing.service');

/**
 * @param {{ paymentClient?: object, mapper?: object, paymentRepository?: object, merchantService?: object, storeService?: object, billingService?: object, logger?: object }} [deps]
 */
function createPaymentService({
  paymentClient = defaultPaymentClient,
  mapper = defaultMapper,
  paymentRepository = defaultPaymentRepository,
  merchantService = defaultMerchantService,
  storeService = defaultStoreService,
  billingService = defaultBillingService,
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
   * Registers a `PaymentPage` online terminal for this store the first time it's needed, and
   * caches the result — see this file's header comment.
   * @param {string} merchantId
   * @param {string} storeId
   * @returns {Promise<string>} terminalId
   */
  async function getOrCreateTerminalId(merchantId, storeId) {
    const cached = await paymentRepository.getTerminalId(storeId);
    if (cached) return cached;

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
   * Creates an order and immediately initiates payment against it — see
   * web-guides/payment-lifecycle.md's "Create an Order" + "Initiate a Payment" steps.
   *
   * `items` is resolved through `billingService.resolveCheckoutItems()` — never trusted as-is —
   * so the client can only ever specify *which* products and *how many*, never their price/tax/
   * discount (see docs/15_SURFBOARD_INTEGRATION.md § 5.1).
   * @param {string} uid
   * @param {{ storeId?: string, items: Array<{ productId: string, quantity: number }> }} input
   */
  async function createCheckout(uid, { storeId: requestedStoreId, items }) {
    const merchantId = await merchantService.getMerchantId(uid);
    const storeId = await resolveStoreId(uid, requestedStoreId);
    const terminalId = await getOrCreateTerminalId(merchantId, storeId);
    const checkoutSummary = await billingService.resolveCheckoutItems(uid, storeId, items);

    const referenceId = `checkout-${uid}-${Date.now()}`;
    const orderWire = mapper.toOrderWire({ terminalId, referenceId, items: checkoutSummary.items });
    const orderRaw = await paymentClient.createOrder(merchantId, orderWire);
    const { orderId } = mapper.toOrderDomain(orderRaw);

    const paymentRaw = await paymentClient.initiatePayment(
      merchantId,
      mapper.toInitiatePaymentWire({ orderId, terminalId }),
    );
    const payment = mapper.toPaymentDomain(paymentRaw);

    logger.info({ uid, storeId, orderId, paymentId: payment.paymentId }, 'Created checkout');
    return {
      orderId,
      storeId,
      subtotal: checkoutSummary.subtotal,
      discountTotal: checkoutSummary.discountTotal,
      taxTotal: checkoutSummary.taxTotal,
      amount: checkoutSummary.grandTotal,
      ...payment,
    };
  }

  /**
   * Re-initiates payment against an existing order — per web-guides/payment-lifecycle.md, a
   * cancelled/failed payment doesn't need a new order.
   * @param {string} uid
   * @param {string} orderId
   * @param {string} storeId
   */
  async function retryPayment(uid, orderId, storeId) {
    const merchantId = await merchantService.getMerchantId(uid);
    await resolveStoreId(uid, storeId);
    const terminalId = await getOrCreateTerminalId(merchantId, storeId);

    const raw = await paymentClient.initiatePayment(
      merchantId,
      mapper.toInitiatePaymentWire({ orderId, terminalId }),
    );
    const payment = mapper.toPaymentDomain(raw);

    logger.info({ uid, orderId, paymentId: payment.paymentId }, 'Retried payment');
    return { orderId, ...payment };
  }

  /**
   * @param {string} uid
   * @param {string} orderId
   */
  async function getCheckoutStatus(uid, orderId) {
    const merchantId = await merchantService.getMerchantId(uid);
    const raw = await paymentClient.getOrderStatus(merchantId, orderId);
    return mapper.toOrderStatusDomain(raw);
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
