# modules/inventory/

Product catalog CRUD and stock mutation (Roadmap Phase 7). The only module permitted to write `products/{merchantId}/{productId}` and `inventory/{storeId}/{productId}` — see docs/07_CODING_RULES.md § 8. See docs/05_FEATURES.md § 4.

- `inventory.service.js` — product CRUD (with soft delete), search/filter/pagination, and per-store stock adjustment. Entirely Firebase-owned — never calls the Surfboard SDK. Resolves `merchantId`/`storeId` ownership via `merchant.service.js#getMerchantId()`/`store.service.js#verifyStoreOwnership()` (cross-module Service calls) rather than reaching into those modules' Repositories — see [docs/08_ARCHITECTURE_DECISIONS.md § ADR-024](../../../../docs/08_ARCHITECTURE_DECISIONS.md#adr-024--inventory-management-in-memory-search--transactional-stock-phase-7).
- `product.repository.js` — the only place `products/{merchantId}/{productId}` is read/written.
- `stock.repository.js` — the only place `inventory/{storeId}/{productId}` is read/written; `adjustQuantity()` uses an RTDB transaction so quantity never goes negative.

Supplier CRUD (task 7.4) and Billing/Payments are not yet implemented.
