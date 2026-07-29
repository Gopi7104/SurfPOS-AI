# modules/merchant/

Merchant application submission/tracking, store registration, profile management. See docs/05_FEATURES.md § 1 and docs/04_API_DOCUMENTATION.md § 3.

- `merchantApplication.service.js` — submits a Merchant Creation request via the Surfboard SDK and tracks it as Firebase-owned application metadata (Roadmap Phase 4). Never duplicates the Merchant object itself, never creates a Store, never writes `users/{uid}.merchantId` — see [docs/08_ARCHITECTURE_DECISIONS.md § ADR-021](../../../../docs/08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4).
- `merchantApplication.repository.js` — the only place `merchantApplications/{uid}` is read/written.
- `merchant.service.js` — Merchant Functions (Roadmap Phase 5): live `GET`/`PATCH` merchant profile + normalized status, via `merchant.client.js`. Never persists the full Merchant object — only refreshes the cached `applicationStatus` snapshot on the same `merchantApplications/{uid}` record.
- `merchant.repository.js` — composes `merchantApplication.repository.js` rather than accessing Firebase directly (both operate on the same node) — see [docs/08_ARCHITECTURE_DECISIONS.md § ADR-022](../../../../docs/08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5).

Store registration (Phase 6) is not yet implemented.
