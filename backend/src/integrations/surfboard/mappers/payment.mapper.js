'use strict';

// Translates between SurfPOS's domain shape and Surfboard's wire format for the Payments family —
// see docs/15_SURFBOARD_INTEGRATION.md § 5. Confirmed against the real bundled docs shipped inside
// the `@surfboardpayments/surf-mcp` npm package (same source ADR-026 used for Merchant Onboarding):
// `api-md/orders-new-create-order.md`, `api-md/orders-new-fetch-order-status.md`,
// `api-md/payments-initiate-a-payment.md`, `api-md/payments-cancel-a-payment.md`,
// `api-md/terminals-register-online-terminal.md`, `web-guides/payment-lifecycle.md`.
//
// SurfPOS has no physical card terminal registered anywhere (see payment.service.js's header
// comment) — every checkout runs through a `PaymentPage`-mode **online** terminal instead. That
// terminal is registered once per store (see payment.service.js#getOrCreateTerminalId) and reused
// for every subsequent order, exactly like a physical terminalId would be.
//
// Only SEK is supported — this app has no currency-selection UI anywhere else (Inventory prices
// are always SEK, see the Product Image phase's test fixtures) and Surfboard's numeric ISO 4217
// code for SEK ("752") appears in every bundled example. Revisit if multi-currency is ever needed.
const CURRENCY_CODE_SEK = '752';

/** Surfboard amounts are integers in the smallest currency unit (öre) — see every bundled example. */
function toMinorUnits(amount) {
  return Math.round(amount * 100);
}

class PaymentMapper {
  /** @returns {object} Register Online Terminal request body (api-md/terminals-register-online-terminal.md) */
  toRegisterTerminalWire() {
    return { onlineTerminalMode: 'PaymentPage' };
  }

  /**
   * @param {{ data?: object }} raw
   * @returns {{ terminalId: string|null }}
   */
  toTerminalDomain(raw = {}) {
    return { terminalId: raw.data?.terminalId ?? null };
  }

  /**
   * @param {{ terminalId: string, referenceId: string, items: Array<{ productId: string, name: string, quantity: number, unitPrice: number, taxPercentage: number, discountPercentage: number }> }} domain
   * @returns {object} Create Order request body (api-md/orders-new-create-order.md) — order-level
   *   `totalOrderAmount.tax` is deliberately omitted: it would need one blended tax percentage
   *   across every line, which isn't meaningful when lines carry different rates. Each line's own
   *   `amount.tax` carries its real rate instead.
   */
  toOrderWire({ terminalId, referenceId, items }) {
    const orderLines = items.map((item) => {
      const lineSubtotal = item.unitPrice * item.quantity;
      const lineDiscount = lineSubtotal * (item.discountPercentage / 100);
      const lineTax = (lineSubtotal - lineDiscount) * (item.taxPercentage / 100);
      const lineTotal = lineSubtotal - lineDiscount + lineTax;

      return {
        id: item.productId,
        name: item.name,
        quantity: item.quantity,
        amount: {
          regular: toMinorUnits(item.unitPrice),
          campaign: toMinorUnits(lineDiscount),
          total: toMinorUnits(lineTotal),
          currency: CURRENCY_CODE_SEK,
          tax: [{ amount: toMinorUnits(lineTax), percentage: item.taxPercentage, type: 'VAT' }],
        },
      };
    });

    const totals = items.reduce(
      (acc, item) => {
        const lineSubtotal = item.unitPrice * item.quantity;
        const lineDiscount = lineSubtotal * (item.discountPercentage / 100);
        const lineTax = (lineSubtotal - lineDiscount) * (item.taxPercentage / 100);
        return {
          regular: acc.regular + lineSubtotal,
          campaign: acc.campaign + lineDiscount,
          total: acc.total + (lineSubtotal - lineDiscount + lineTax),
        };
      },
      { regular: 0, campaign: 0, total: 0 },
    );

    return {
      terminal$id: terminalId,
      referenceId,
      orderLines,
      totalOrderAmount: {
        regular: toMinorUnits(totals.regular),
        campaign: toMinorUnits(totals.campaign),
        total: toMinorUnits(totals.total),
        currency: CURRENCY_CODE_SEK,
      },
    };
  }

  /**
   * @param {{ data?: object }} raw
   * @returns {{ orderId: string|null }}
   */
  toOrderDomain(raw = {}) {
    return { orderId: raw.data?.orderId ?? null };
  }

  /**
   * @param {{ orderId: string, terminalId: string }} domain
   * @returns {object} Initiate a Payment request body (api-md/payments-initiate-a-payment.md) —
   *   `paymentMethod` is hardcoded to `CARD`, the only method this app's Checkout UI offers.
   */
  toInitiatePaymentWire({ orderId, terminalId }) {
    return { orderId, terminalId, paymentMethod: 'CARD' };
  }

  /**
   * @param {{ data?: object }} raw
   * @returns {{ paymentId: string|null, paymentUrl: string|null, qr: string|null, qrData: string|null, qrLink: string|null }}
   */
  toPaymentDomain(raw = {}) {
    const data = raw.data ?? {};
    return {
      paymentId: data.paymentId ?? null,
      paymentUrl: data.paymentUrl ?? null,
      qr: data.qr ?? null,
      qrData: data.qrData ?? null,
      qrLink: data.qrLink ?? null,
    };
  }

  /**
   * @param {{ data?: object }} raw Fetch Order Status envelope (api-md/orders-new-fetch-order-status.md)
   * @returns {{ orderStatus: string|null, paymentStatus: string|null, paymentId: string|null, paymentMethod: string|null, amount: number|null, failureReason: string|null, transactionId: string|null }}
   */
  toOrderStatusDomain(raw = {}) {
    const data = raw.data ?? {};
    const payment = (data.payments ?? [])[0] ?? {};
    const transaction = (data.transactions ?? [])[0] ?? {};
    return {
      orderStatus: data.orderStatus ?? null,
      paymentStatus: payment.paymentStatus ?? null,
      paymentId: payment.paymentId ?? null,
      paymentMethod: payment.paymentMethod ?? null,
      amount: payment.amount ?? null,
      failureReason: payment.failureReason ?? null,
      transactionId: transaction.transactionId ?? null,
    };
  }

  /**
   * @param {{ data?: object }} raw Cancel a Payment envelope (api-md/payments-cancel-a-payment.md)
   * @returns {{ paymentStatus: string|null }}
   */
  toCancelDomain(raw = {}) {
    return { paymentStatus: raw.data?.paymentStatus ?? null };
  }
}

module.exports = new PaymentMapper();
module.exports.PaymentMapper = PaymentMapper;
module.exports.CURRENCY_CODE_SEK = CURRENCY_CODE_SEK;
