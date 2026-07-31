'use strict';

// Request-shape validation for Checkout/Payments — see docs/07_CODING_RULES.md § 10. Only line
// items are accepted from the client; totals are always recomputed server-side (never trusted from
// the request), per docs/15_SURFBOARD_INTEGRATION.md § 5.1 — see payment.service.js.

const { z } = require('zod');

const checkoutItemSchema = z.object({
  productId: z.string().min(1),
  quantity: z.number().int().positive(),
});

const createCheckoutSchema = z.object({
  storeId: z.string().min(1).optional(),
  items: z.array(checkoutItemSchema).min(1),
});

const retryCheckoutSchema = z.object({
  storeId: z.string().min(1),
});

const orderIdParamsSchema = z.object({
  orderId: z.string().min(1),
});

const paymentIdParamsSchema = z.object({
  paymentId: z.string().min(1),
});

module.exports = {
  createCheckoutSchema,
  retryCheckoutSchema,
  orderIdParamsSchema,
  paymentIdParamsSchema,
};
