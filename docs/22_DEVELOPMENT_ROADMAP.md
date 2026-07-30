# 22 — Development Roadmap

> **New document, added during the Surfboard-alignment documentation pass — this supersedes the old Phase 0/1/2/3 structure described in earlier versions of [10_TASKS.md](10_TASKS.md).** This file is the authoritative *phase order and rationale*; [10_TASKS.md](10_TASKS.md) is the granular, live-status task table using these same phase numbers/names. If the two ever disagree on phase order, this file wins — update [10_TASKS.md](10_TASKS.md) to match rather than the reverse.

---

## Why This Order

The old roadmap sequenced work by *feature area* (auth → catalog → inventory → billing → payments) on the assumption that Firebase owned merchant/store/payment data outright, so those features could be built independently of Surfboard. That assumption is now known to be wrong (see [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)): almost every feature needs a working Surfboard integration layer underneath it before it can do anything real. This roadmap instead sequences work **bottom-up through the integration**: build the Surfboard client SDK once, then light up each Surfboard-owned capability in the order SurfPOS actually needs it (identity → merchant → store → *then* the Firebase-owned features that depend on a real store existing → payments → the remaining Surfboard capabilities → analytics/AI last, since both are read-only rollups over everything before them).

## Prerequisites (block Phase 2, not numbered as their own phase)

These are environment/credential setup, not application code — they must exist before Phase 2 can do anything real, but they don't get a phase number because there's no SurfPOS code to sequence around them:

- Firebase project created (Auth, Realtime Database, Storage) — see [14_DEVELOPER_GUIDE.md § 5](14_DEVELOPER_GUIDE.md#5-firebase-setup).
- Surfboard Payments sandbox/developer account + API credentials + confirmed API documentation.
- Gemini API key (only blocks Phase 13, not Phase 2–12).
- Remaining open ADR-009 items that block specific later phases (OCR provider blocks Phase 13 only; production font blocks nothing backend-related).

---

## Phase 1 — Backend Foundation ✅ Done

Express app bootstrap, environment config, structured logging, Firebase Admin SDK init (lazy), global error handling, standard response envelope, request validation middleware, `GET /health`, plus infrastructure hardening (lint/format/pre-commit hooks, compression, rate limiting, `constants/`/`types/` layers, placeholder Surfboard integration client files, CI). See [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) for the two sessions that built this.

**Exit criteria (met):** server boots, `/health` returns the standard envelope, full lint/format/test/build pipeline is green.

## Phase 2 — Surfboard Client SDK ✅ Done

Built out the real HTTP plumbing behind `src/integrations/surfboard/*.client.js`: `client/` (base HTTP client + environment-aware config), `middleware/` (retry, timeout, auth-header placeholder, request/response logging), `models/` (JSDoc-only request/response/environment shapes), `mappers/` (the `BaseMapper` contract future domain mappers will implement), `utils/` (request ID generation, request building, response parsing, webhook signature verification), `errors/` (`SurfboardApiError` + a normalizing error mapper). All six domain clients now inherit a fully working `request()` — auth headers, retry, timeout, request IDs, and logging happen automatically — but **no domain method was added to any of them** (no `createMerchant()`, no `createPaymentIntent()`, etc.); that's still deferred to each entity's owning phase. 48 unit tests cover the SDK against a mocked `fetch`, never a real network call. See [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) for implementation notes and open placeholders (auth scheme, base URL, webhook signature scheme — all pending official Surfboard docs).

**Exit criteria (met):** every domain client boots and its `request()` correctly handles success, retryable failures, non-retryable failures, and timeouts against a mocked HTTP layer; full lint/format/test/build pipeline is green.

**Depended on:** nothing blocking — real Surfboard sandbox credentials are still needed before Phase 2's placeholder base URL/auth scheme can be confirmed, but building the SDK shape itself did not require them. **Blocks:** every phase after it (now unblocked).

## Phase 3 — Client Authentication

Firebase Auth sign-up/sign-in (email/password + phone OTP), `auth.middleware.js` token verification (already scaffolded), and `GET /auth/me` resolving `users/{uid}` → `merchantId`/`storeIds` references. This is SurfPOS identity, distinct from Surfboard — it's sequenced here because Merchant Creation (Phase 4) needs an authenticated owner to attach the new merchant reference to.

## Phase 4 — Merchant Creation

> **This section describes the original plan; it was re-scoped during implementation.** `POST /auth/register` as described below was never built — see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4) for what was actually implemented (`POST/GET /merchant/applications`), and [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction) for the now-confirmed real Surfboard wire format (this section's shape below was always a placeholder, never sent over the wire). [10_TASKS.md](10_TASKS.md) Phase 4 is authoritative for current status.

`POST /auth/register` orchestrates: Firebase Auth account (already created client-side) → Surfboard Merchant Creation call (via Phase 2's client) → `users/{uid}.merchantId` reference write. See [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle).

## Phase 5 — Merchant Functions

> **Wire format confirmed** — see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction). `GET /merchant/status` is backed by Surfboard's real Check Application Status endpoint, not a derived view of `GET /merchant` as originally assumed (ADR-022).

`GET/PATCH` merchant profile proxy endpoints, staff invite flow (`POST /auth/staff-invite`, Firebase-owned — staff are a SurfPOS access-control concept, not a Surfboard one). See [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle).

## Phase 6 — Store Capabilities

Default Store creation (part of registration), Store profile proxy endpoints, and Payment Methods querying (folded into the Store module per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split)). See [19_SURFBOARD_WORKFLOWS.md §§ 2, 7](19_SURFBOARD_WORKFLOWS.md#2-store-lifecycle).

**Exit criteria:** a registered merchant has a real Surfboard Store ID to partition every subsequent Firebase-owned feature by — this unblocks Phases 7–8.

## Phase 7 — Inventory

Product catalog CRUD + stock management — entirely Firebase-owned, unchanged in spirit from the original plan, now correctly scoped by a real Surfboard `storeId`/`merchantId` reference instead of a locally-invented one. See [20_DOMAIN_MODEL.md §§ 2.8–2.9](20_DOMAIN_MODEL.md#28-inventory--firebase-owned).

## Phase 8 — Billing

Cart/checkout flow, Sale creation and total/tax computation — Firebase-owned, but now stops short of payment execution (that's Phase 9): a Sale is created in `pending_payment` and handed to the Payments module rather than the Billing module owning payment logic itself. See [20_DOMAIN_MODEL.md § 2.10](20_DOMAIN_MODEL.md#210-sale--firebase-owned).

## Phase 9 — Payments

The full Payment lifecycle (creation, webhook confirmation, reconciliation with Sale status) and the folded-in Tips workflow. See [19_SURFBOARD_WORKFLOWS.md §§ 4, 6](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle).

## Phase 10 — Device Management

Linking/unlinking Surfboard card-reader devices to a Store, device status queries. See [19_SURFBOARD_WORKFLOWS.md § 3](19_SURFBOARD_WORKFLOWS.md#3-device-lifecycle).

## Phase 11 — Branding

Merchant branding proxy endpoints (logo, color, receipt footer as recognized by Surfboard's own surfaces) — distinct from SurfPOS's own receipt template. See [19_SURFBOARD_WORKFLOWS.md § 5](19_SURFBOARD_WORKFLOWS.md#5-branding-workflow).

## Phase 12 — Analytics

Precomputed rollup jobs over `sales`/`inventory` (Firebase-owned), Dashboard/Reports endpoints. Sequenced after Payments/Billing since analytics has nothing to aggregate until real sales exist.

## Phase 13 — AI

OCR + Gemini invoice scanning, product matching, business insight generation — unchanged in shape from [16_AI_MODULE.md](16_AI_MODULE.md), sequenced last since it's the most speculative/least-blocking-to-everything-else capability, and still has an open ADR-009 item (OCR provider choice).

---

## Explicitly Not Phased Yet

Multi-store UI, offline billing, customer loyalty/CRM, supplier portal, and the other items in [01_PROJECT_OVERVIEW.md § 6 Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope) remain unscheduled beyond Phase 13.

---

**Next:** [10_TASKS.md](10_TASKS.md) — the granular task table tracking status within each phase above.
