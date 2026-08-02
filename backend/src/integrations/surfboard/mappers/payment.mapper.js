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
   * @param {{ terminalId: string, referenceId: string, items: Array<{ productId: string, name: string, quantity: number, unitPrice: number, taxPercentage: number, discountPercentage: number }>, redirectUrls?: { success: string, failure: string, callBackUrl?: string } }} domain
   *   `redirectUrls` is omitted entirely when unset (see payment.service.js#buildRedirectUrls) —
   *   Surfboard rejects both non-http(s) schemes and private/loopback addresses for these fields
   *   (confirmed live), so a typical local-LAN dev backend simply never includes this block and
   *   Checkout still works via status polling (docs/15_SURFBOARD_INTEGRATION.md § 5.3's documented
   *   fallback) — this is not a degraded mode, it's the same fallback Surfboard's own webhook docs
   *   recommend even for a fully public production backend.
   * @returns {object} Create Order request body (api-md/orders-new-create-order.md) — order-level
   *   `totalOrderAmount.tax` is deliberately omitted: it would need one blended tax percentage
   *   across every line, which isn't meaningful when lines carry different rates. Each line's own
   *   `amount.tax` carries its real rate instead.
   *
   * Three validation rules confirmed live against the real sandbox, one at a time (none is
   * documented anywhere in the bundled docs beyond a brief mention — no worked example combines
   * tax + discount + quantity > 1, which is exactly the combination that exposed all three):
   *  1. Every LINE `amount` object must satisfy `total === regular + shipping - campaign` — a
   *     naive `regular: unitPrice, total: taxInclusiveLineTotal` mismatch is rejected with
   *     `OR_0023: Invalid item price`. `total` is fixed to the real amount owed; `regular` is
   *     derived FROM it (`total + campaign`) so the identity holds by construction.
   *  2. Per `web-guides/create-an-order.md`'s "Order Line Level Calculation" table, the default
   *     (`orderLineLevelCalculation: false`, which this app always uses) formula for
   *     `totalOrderAmount` is "Sum of (total × quantity) per line" — each line's own `amount.*`
   *     fields are **per-unit**, not pre-multiplied by quantity; Surfboard multiplies by quantity
   *     itself. Passing an already-quantity-multiplied line total makes `totalOrderAmount`
   *     inconsistent with the lines, rejected with `OR_0037: Invalid total order price`.
   *  3. Unlike a line's own `amount`, `totalOrderAmount.regular` must equal `.total` directly and
   *     `.campaign` must be `0` — confirmed by testing every combination live: `regular =
   *     total + campaign` (mirroring the line-level rule) was always rejected with `OR_0037`;
   *     `regular = total` with a *non-zero* `campaign` was ALSO rejected; only `regular = total`
   *     WITH `campaign: 0` succeeded, regardless of tax/quantity/discount on the lines themselves.
   *     The real per-line discount is still fully reported in each line's own `amount.campaign`.
   */
  toOrderWire({ terminalId, referenceId, items, redirectUrls }) {
    const perUnit = items.map((item) => {
      const unitDiscount = item.unitPrice * (item.discountPercentage / 100);
      const unitTax = (item.unitPrice - unitDiscount) * (item.taxPercentage / 100);
      const unitTotal = item.unitPrice - unitDiscount + unitTax;

      const totalMinor = toMinorUnits(unitTotal);
      const campaignMinor = toMinorUnits(unitDiscount);
      return { totalMinor, campaignMinor, taxMinor: toMinorUnits(unitTax) };
    });

    const orderLines = items.map((item, index) => {
      const { totalMinor, campaignMinor, taxMinor } = perUnit[index];
      return {
        id: item.productId,
        name: item.name,
        quantity: item.quantity,
        amount: {
          regular: totalMinor + campaignMinor,
          campaign: campaignMinor,
          total: totalMinor,
          currency: CURRENCY_CODE_SEK,
          tax: [{ amount: taxMinor, percentage: item.taxPercentage, type: 'VAT' }],
        },
      };
    });

    const orderTotalMinor = items.reduce(
      (sum, item, index) => sum + perUnit[index].totalMinor * item.quantity,
      0,
    );

    // Confirmed live: even though "createOrder lets you create and pay for an order in a single
    // call" per its own docs, a PaymentPage-mode online terminal (see toRegisterTerminalWire())
    // generates its hosted payment link purely from the order/terminal itself — this block makes
    // no observed difference to the response, but is included since it's what every bundled
    // worked example shows and it's the one place the intended `paymentMethod` is documented.
    // Never call Initiate a Payment afterward for this terminal type — confirmed live to fail
    // with `PS_0025: Payment initiation failed` (destructuring 'omniPayment' from null), since the
    // order already carries its own payment context.
    const controlFunctions = { initiatePaymentsOptions: { paymentMethod: 'CARD' } };

    if (redirectUrls) {
      // Field names/nesting (`controlFunctions.online.{redirectUrl,failureRedirectUrl}`) are from
      // the bundled narrative guides (web-guides/payment-page.md,
      // guides/in-store-payments/your-first-payment/create-order/home.md) — NOT in the formal
      // orders-new-create-order.md reference table (same undocumented-field gap as
      // toOrderDomain()'s `paymentPageLink`). `generateShortLink` shortens the redirect-back
      // URL Surfboard appends `?orderId=...` to. `callBackUrl` (per-order webhook) IS in the
      // formal reference table — see web-guides/webhooks-notifications.md § "Callback URL".
      controlFunctions.online = {
        redirectUrl: redirectUrls.success,
        failureRedirectUrl: redirectUrls.failure,
        generateShortLink: true,
      };
      if (redirectUrls.callBackUrl) {
        controlFunctions.callBackUrl = redirectUrls.callBackUrl;
      }
    }

    return {
      terminal$id: terminalId,
      referenceId,
      orderLines,
      totalOrderAmount: {
        // regular === total and campaign === 0 at THIS level, always (see rule 3 above) — the
        // real discount is fully reported per-line instead.
        regular: orderTotalMinor,
        campaign: 0,
        total: orderTotalMinor,
        currency: CURRENCY_CODE_SEK,
      },
      controlFunctions,
    };
  }

  /**
   * @param {{ data?: object }} raw
   * @returns {{ orderId: string|null, paymentUrl: string|null }} `paymentUrl` is Surfboard's
   *   `paymentPageLink` — confirmed live against the real sandbox (Create Order's own docs never
   *   document a response body at all; this field name isn't mentioned anywhere in the bundled
   *   docs, only Initiate a Payment's separate, unrelated `paymentUrl` field is).
   */
  toOrderDomain(raw = {}) {
    const data = raw.data ?? {};
    return { orderId: data.orderId ?? null, paymentUrl: data.paymentPageLink ?? null };
  }

  /**
   * NOT used by the current PaymentPage flow — payment.service.js never calls Initiate a Payment
   * (confirmed live to fail with `PS_0025` for a PaymentPage-mode order, see toOrderWire's doc
   * comment). Kept, correctly implemented against the confirmed docs
   * (api-md/payments-initiate-a-payment.md), for a possible future physical/CARD-present terminal
   * flow, where this two-step create-then-initiate pattern is the documented one.
   * @param {{ orderId: string, terminalId: string }} domain
   * @returns {object} Initiate a Payment request body — `paymentMethod` is hardcoded to `CARD`,
   *   the only method this app's Checkout UI offers.
   */
  toInitiatePaymentWire({ orderId, terminalId }) {
    return { orderId, terminalId, paymentMethod: 'CARD' };
  }

  /**
   * Pairs with toInitiatePaymentWire() — see that method's doc comment for why this is currently
   * unused by payment.service.js.
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
