# modules/payments/

Checkout's Surfboard order/payment orchestration (Phase 4, see docs/22_DEVELOPMENT_ROADMAP.md).

- `payment.service.js` — resolves merchant/store, registers a software-only online terminal per
  store on first use (cached via `payment.repository.js`), delegates cart validation/pricing to
  `modules/billing/billing.service.js`, then creates a Surfboard order + initiates payment via
  `integrations/surfboard/payment.client.js`. Also exposes retry/status-poll/cancel.
- `payment.repository.js` — the only place `onlineTerminals/{storeId}` (the cached online
  terminalId) is read or written.

Deliberately out of scope this phase: no `sales/{storeId}/{saleId}` Firebase record is created, no
webhook handler, no receipt/inventory-decrement side effects (see `modules/surfboard/README.md`,
still a scaffold — webhook reconciliation is future work). This module only ever asks Surfboard
live for the current order/payment status; the Flutter app polls it directly.
