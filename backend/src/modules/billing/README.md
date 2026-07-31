# modules/billing/

Cart validation, sale total/tax computation. The only module permitted to compute sale totals. See docs/05_FEATURES.md § 7.

`billing.service.js#resolveCheckoutItems()` (Phase 4) re-resolves every `{ productId, quantity }`
line a client sends against `modules/inventory/inventory.service.js`'s live catalog — never trusting
a client-submitted price/tax/discount — and computes subtotal/discount/tax/grand-total. Used by
`modules/payments/payment.service.js#createCheckout` before any Surfboard order is created (see
docs/15_SURFBOARD_INTEGRATION.md § 5.1).

Sale lifecycle (a persisted `sales/{storeId}/{saleId}` record) is not yet implemented — out of
scope for Phase 4 (no receipt/inventory-decrement side effects yet).
