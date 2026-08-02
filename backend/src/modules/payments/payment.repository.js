'use strict';

// The only place `onlineTerminals/{storeId}` and `orderPaymentUrls/{orderId}` are read or written.
//
// `onlineTerminals/{storeId}` caches the software-only online terminalId Surfboard assigns a store
// the first time it takes a payment (see payment.service.js#getOrCreateTerminalId) — registering
// one is a one-time setup per store, not a per-checkout call, so it's cached the same way
// modules/store/store.repository.js caches which storeIds SurfPOS created.
//
// `orderPaymentUrls/{orderId}` caches the hosted Payment Page link Create Order returns — kept for
// display/debugging (e.g. re-showing the last link a given order used), but retryPayment() no
// longer re-serves it: Surfboard's hosted Payment Page is a one-shot session tied to the order it
// was created for (there is no Surfboard endpoint to re-fetch/regenerate a link for an *existing*
// order — Fetch Order Status's response never includes one), so once the customer's browser
// reaches that page and the attempt ends (success, failure, or cancel), reopening the same link
// shows Surfboard's own "Invalid or Expired Link" page regardless of the order's own
// PENDING/retryable status. The only documented way to obtain a fresh, openable link is a new
// Create Order call — see payment.service.js#retryPayment.
//
// `orderCheckoutItems/{orderId}` caches the client-submitted `{ productId, quantity }` lines (never
// price/tax/discount — those are always re-resolved live via billingService, same rule as the
// original checkout) so retryPayment() can rebuild a brand-new order for the same cart without the
// caller having to resend it.
//
// Takes its Firebase accessor as a DI parameter (docs/21_BACKEND_GUIDELINES.md § 12), same as
// every other Repository in this codebase.

const { getDb: defaultGetDb } = require('../../firebase/admin');

/**
 * @param {{ getDb?: () => import('firebase-admin').database.Database }} [deps]
 */
function createPaymentRepository({ getDb = defaultGetDb } = {}) {
  /**
   * @param {string} storeId
   * @returns {Promise<string|null>}
   */
  async function getTerminalId(storeId) {
    const snapshot = await getDb().ref(`onlineTerminals/${storeId}`).once('value');
    return snapshot.val()?.terminalId ?? null;
  }

  /**
   * @param {string} storeId
   * @param {string} terminalId
   */
  async function setTerminalId(storeId, terminalId) {
    await getDb().ref(`onlineTerminals/${storeId}`).set({ terminalId, createdAt: Date.now() });
  }

  /**
   * @param {string} orderId
   * @returns {Promise<string|null>}
   */
  async function getPaymentUrl(orderId) {
    const snapshot = await getDb().ref(`orderPaymentUrls/${orderId}`).once('value');
    return snapshot.val()?.paymentUrl ?? null;
  }

  /**
   * @param {string} orderId
   * @param {string} paymentUrl
   */
  async function setPaymentUrl(orderId, paymentUrl) {
    await getDb().ref(`orderPaymentUrls/${orderId}`).set({ paymentUrl, createdAt: Date.now() });
  }

  /**
   * @param {string} orderId
   * @returns {Promise<Array<{ productId: string, quantity: number }>|null>}
   */
  async function getCheckoutItems(orderId) {
    const snapshot = await getDb().ref(`orderCheckoutItems/${orderId}`).once('value');
    return snapshot.val()?.items ?? null;
  }

  /**
   * @param {string} orderId
   * @param {Array<{ productId: string, quantity: number }>} items
   */
  async function setCheckoutItems(orderId, items) {
    await getDb().ref(`orderCheckoutItems/${orderId}`).set({ items, createdAt: Date.now() });
  }

  /**
   * @param {string} orderId
   * @returns {Promise<object|null>} the domain-shaped status `webhook.controller.js` cached via
   *   `setWebhookStatus`, or `null` if no terminal webhook has arrived yet for this order.
   */
  async function getWebhookStatus(orderId) {
    const snapshot = await getDb().ref(`webhookOrderStatus/${orderId}`).once('value');
    return snapshot.val()?.status ?? null;
  }

  /**
   * Caches a terminal payment outcome as soon as Surfboard's webhook reports it — see
   * payment.mapper.js#toWebhookStatusDomain's header comment for why this exists (the webhook
   * beats Fetch Order Status to a completed payment by a wide, sometimes multi-minute margin on
   * Surfboard's sandbox). `status` is only ever one of the three terminal states (enforced by
   * `toWebhookStatusDomain` returning `null` for anything else), so this never needs to guard
   * against overwriting a terminal result with a non-terminal one — every write here already is
   * terminal, matching web-guides/webhooks-notifications.md's "treat these three statuses as
   * final" rule by construction.
   * @param {string} orderId
   * @param {object} status the domain-shaped status object to cache verbatim
   */
  async function setWebhookStatus(orderId, status) {
    await getDb().ref(`webhookOrderStatus/${orderId}`).set({ status, createdAt: Date.now() });
  }

  return {
    getTerminalId,
    setTerminalId,
    getPaymentUrl,
    setPaymentUrl,
    getCheckoutItems,
    setCheckoutItems,
    getWebhookStatus,
    setWebhookStatus,
  };
}

module.exports = createPaymentRepository();
module.exports.createPaymentRepository = createPaymentRepository;
