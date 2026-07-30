# modules/store/

Store Capabilities (Roadmap Phase 6). See docs/05_FEATURES.md § 14 and docs/04_API_DOCUMENTATION.md § 3.

- `store.service.js` — creates/fetches/updates the live Surfboard Store for the caller's own merchant (resolved via `merchant.service.js#getMerchantId()`, a cross-module Service call). `GET /stores` lists from SurfPOS's own local registry (see below) since no Surfboard list-stores-by-merchant endpoint is confirmed — see [docs/08_ARCHITECTURE_DECISIONS.md § ADR-023](../../../../docs/08_ARCHITECTURE_DECISIONS.md#adr-023--store-capabilities-local-registry--no-invented-list-endpoint-phase-6).
- `store.repository.js` — the only place `storeReferences/{uid}/{storeId}` is read/written. A minimal local registry of storeIds SurfPOS created, never the full Store object.

Inventory, Billing, Payments, Device Management, Branding, Analytics, and AI are not yet implemented.
