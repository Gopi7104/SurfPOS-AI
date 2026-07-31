'use strict';

// Surfboard payment/order API — see docs/15_SURFBOARD_INTEGRATION.md § 5. Wire format confirmed
// against the real Surfboard docs bundled inside the `@surfboardpayments/surf-mcp` npm package
// (same source ADR-026 used to confirm Merchant Onboarding) — see mappers/payment.mapper.js's
// header comment for the exact files. Isolated to this file + payment.mapper.js, same as every
// other confirmed Surfboard domain client.

const SurfboardBaseClient = require('./client/surfboardClient.base');

class SurfboardPaymentClient extends SurfboardBaseClient {
  /**
   * Registers a software-only online terminal for a store — no physical hardware involved. See
   * `api-md/terminals-register-online-terminal.md`. SurfPOS has never registered a physical
   * terminal (see `device.client.js`, still a placeholder), so every checkout runs through one of
   * these instead (see payment.service.js#getOrCreateTerminalId).
   * @param {string} merchantId
   * @param {string} storeId
   * @param {{ onlineTerminalMode: 'PaymentPage'|'SelfHostedPage'|'MerchantInitiated' }} wirePayload
   * @returns {Promise<object>} raw Surfboard response body ({ status, data, message })
   */
  async registerOnlineTerminal(merchantId, storeId, wirePayload) {
    const { data } = await this.request({
      method: 'POST',
      path: `/merchants/${merchantId}/stores/${storeId}/online-terminals`,
      headers: { 'MERCHANT-ID': merchantId },
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Creates an order — the foundation every payment attempt references. See
   * `api-md/orders-new-create-order.md`. Does not itself initiate a payment (see
   * `initiatePayment()`) — kept as two calls so the payment response's `paymentUrl`/`qr` fields
   * (only documented on Initiate a Payment's response, never on Create Order's) are available.
   * @param {string} merchantId
   * @param {object} wirePayload — already in Surfboard's wire format (see payment.mapper.js#toOrderWire)
   * @returns {Promise<object>} raw Surfboard response body ({ status, data: { orderId }, message })
   */
  async createOrder(merchantId, wirePayload) {
    const { data } = await this.request({
      method: 'POST',
      path: '/orders',
      headers: { 'MERCHANT-ID': merchantId },
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Initiates (or retries) a payment against an existing order — see
   * `api-md/payments-initiate-a-payment.md`. Per `web-guides/payment-lifecycle.md`, a cancelled or
   * failed payment doesn't need a new order: call this again with the same `orderId` to retry.
   * @param {string} merchantId
   * @param {object} wirePayload — already in Surfboard's wire format (see payment.mapper.js#toInitiatePaymentWire)
   * @returns {Promise<object>} raw Surfboard response body ({ status, data: { paymentId, paymentUrl, qr, ... }, message })
   */
  async initiatePayment(merchantId, wirePayload) {
    const { data } = await this.request({
      method: 'POST',
      path: '/payments',
      headers: { 'MERCHANT-ID': merchantId },
      body: wirePayload,
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Fetches the current order + payment + transaction status — the source of truth this backend
   * polls from (see docs/15_SURFBOARD_INTEGRATION.md § 5.3). See
   * `api-md/orders-new-fetch-order-status.md`.
   * @param {string} merchantId
   * @param {string} orderId
   * @returns {Promise<object>} raw Surfboard response body
   */
  async getOrderStatus(merchantId, orderId) {
    const { data } = await this.request({
      method: 'GET',
      path: `/orders/${orderId}/status`,
      headers: { 'MERCHANT-ID': merchantId },
      expectsEnvelope: true,
    });
    return data;
  }

  /**
   * Cancels an in-progress (not yet completed) payment. See `api-md/payments-cancel-a-payment.md`.
   * @param {string} merchantId
   * @param {string} paymentId
   * @returns {Promise<object>} raw Surfboard response body ({ status, data: { paymentStatus }, message })
   */
  async cancelPayment(merchantId, paymentId) {
    const { data } = await this.request({
      method: 'DELETE',
      path: `/payments/${paymentId}`,
      headers: { 'MERCHANT-ID': merchantId },
      expectsEnvelope: true,
    });
    return data;
  }
}

module.exports = new SurfboardPaymentClient();
module.exports.SurfboardPaymentClient = SurfboardPaymentClient;
