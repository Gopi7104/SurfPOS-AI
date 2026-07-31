'use strict';

// Cart validation, sale total/tax computation — see docs/05_FEATURES.md § 7 and this module's own
// README ("the only module permitted to compute sale totals"). modules/payments/payment.service.js
// depends on this instead of trusting client-submitted unitPrice/tax/discount per line, per
// docs/15_SURFBOARD_INTEGRATION.md § 5.1 ("Never create the payment intent for a client-submitted
// amount directly — only for the backend-recomputed total"). The client only ever sends
// {productId, quantity} per line (see validators/payment.validation.js) — every price/tax/discount
// figure is read live from modules/inventory/inventory.service.js, the same authority the Inventory
// screens themselves read from, so a modified client can never under-pay by forging a lower price.

const { ValidationError } = require('../../utils/errors');
const defaultInventoryService = require('../inventory/inventory.service');

/**
 * @param {{ inventoryService?: object }} [deps]
 */
function createBillingService({ inventoryService = defaultInventoryService } = {}) {
  function computeLine({ unitPrice, quantity, taxPercentage, discountPercentage }) {
    const lineSubtotal = unitPrice * quantity;
    const lineDiscount = lineSubtotal * (discountPercentage / 100);
    const lineTax = (lineSubtotal - lineDiscount) * (taxPercentage / 100);
    return { lineSubtotal, lineDiscount, lineTax, lineTotal: lineSubtotal - lineDiscount + lineTax };
  }

  /**
   * Resolves each `{ productId, quantity }` against the merchant's live catalog — ignoring any
   * name/price the client might have sent — and computes the cart's totals server-side. The
   * caller (payment.service.js) is responsible for having already verified `storeId` ownership.
   * @param {string} uid
   * @param {string} storeId
   * @param {Array<{ productId: string, quantity: number }>} cartItems
   * @returns {Promise<{ items: Array<{ productId: string, name: string, quantity: number, unitPrice: number, taxPercentage: number, discountPercentage: number }>, subtotal: number, discountTotal: number, taxTotal: number, grandTotal: number }>}
   */
  async function resolveCheckoutItems(uid, storeId, cartItems) {
    if (!cartItems?.length) {
      throw new ValidationError('At least one item is required');
    }

    const items = await Promise.all(
      cartItems.map(async ({ productId, quantity }) => {
        const product = await inventoryService.getProduct(uid, productId, { storeId });
        return {
          productId: product.id,
          name: product.name,
          quantity,
          unitPrice: product.sellingPrice ?? 0,
          taxPercentage: product.taxRate ?? 0,
          discountPercentage: product.discountPercentage ?? 0,
        };
      }),
    );

    const totals = items.reduce(
      (acc, item) => {
        const line = computeLine(item);
        return {
          subtotal: acc.subtotal + line.lineSubtotal,
          discountTotal: acc.discountTotal + line.lineDiscount,
          taxTotal: acc.taxTotal + line.lineTax,
          grandTotal: acc.grandTotal + line.lineTotal,
        };
      },
      { subtotal: 0, discountTotal: 0, taxTotal: 0, grandTotal: 0 },
    );

    return { items, ...totals };
  }

  return { resolveCheckoutItems };
}

module.exports = createBillingService();
module.exports.createBillingService = createBillingService;
