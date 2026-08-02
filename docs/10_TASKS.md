# 10 — Tasks / Roadmap

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file, including the old Phase 0/1/2/3 structure.** Related: [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) (the authoritative phase order and *why*, read that first), [05_FEATURES.md](05_FEATURES.md) (what each task builds), [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (decisions each task depends on), [11_CHANGELOG.md](11_CHANGELOG.md) (what's actually shipped).

---

## How to Use This File

Every task has: **Priority** (P0 = blocking/critical, P1 = important, P2 = nice-to-have), **Status** (`Not Started` / `In Progress` / `Blocked` / `Done`), **Dependencies**, **Owner** (`Unassigned` until claimed). Phase numbers/names match [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) exactly — if they ever disagree, that file wins.

---

## Prerequisites (block Phase 2)

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| P.1 | Firebase project setup (Auth, RTDB, Storage) + `database.rules.json` skeleton (application data only) | P0 | Auth + RTDB: Done (backend + frontend wired, both live-verified against the real `surfpos-ai` project); Storage: deliberately deferred — `FIREBASE_STORAGE_BUCKET` intentionally left unset for now, revisit when Storage is actually needed (Receipts/AI invoice images) | — | Claude |
| P.2 | Surfboard Payments sandbox/developer account + API credentials + official API documentation | P0 | Not Started | — | Unassigned |
| P.3 | OpenRouter API key provisioning (blocks Phase 13 only) | P0 | Not Started | — | Unassigned |
| P.4 | Resolve remaining [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) items relevant to near-term phases (real-time client strategy — blocks Phase 8/12) | P0 | Not Started | — | Unassigned |

## Phase 1 — Backend Foundation ✅ Done

**Backend track (as actually shipped, matches the header above):**

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 1.1 | Express app bootstrap, env config, logger, Firebase Admin SDK init, auth/validation/error middleware, response helper, `GET /health` | P0 | Done | — | Claude |
| 1.2 | Infrastructure hardening: ESLint/Prettier/Husky, compression + rate limiting, `constants/`/`types/` layers, placeholder Surfboard integration clients, richer logging, tests, CI | P0 | Done | 1.1 | Claude |
| 1.3 | Documentation realignment to Surfboard-as-system-of-record architecture | P0 | Done | — | Claude |

**Frontend UI track (older Phase 1 numbering scheme, predates the Surfboard-alignment pass — kept for reference, task IDs below are independent of the table above):**

| # | Task | Priority | Status | Dependencies | Est. Time | Owner |
|---|---|---|---|---|---|---|
| 1.0 | Premium Flutter UI: design system (done) + 26 screens, one at a time (1/26 — Splash — done; see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) and `.claude/projectStatus.md`) | P0 | In Progress | 0.6 | ~10 days (26 screens) | Claude |
| 1.1 | Firebase Auth integration (sign-up/sign-in, email + phone OTP) | P0 | Not Started | 0.3 | 2 days | Unassigned |
| 1.2 | Merchant Registration flow (`POST /auth/register`, onboarding wizard UI) | P0 | Not Started | 1.1, 0.4 | 3 days | Unassigned |
| 1.3 | Product catalog CRUD (backend + UI) | P0 | Not Started | 0.3 | 3 days | Unassigned |
| 1.4 | Inventory management (view, manual adjust) | P0 | Not Started | 1.3 | 2 days | Unassigned |
| 1.5 | Barcode scanner (camera-based) | P0 | Not Started | 1.3 | 3 days | Unassigned |
| 1.6 | Cart + Billing checkout flow (client-side cart, `POST /sales`) | P0 | Not Started | 1.3, 1.4 | 4 days | Unassigned |
| 1.7 | Surfboard Payments integration (payment intent, device/SDK flow, webhook) | P0 | Not Started | 0.4, 1.6 | 5 days | Unassigned |
| 1.8 | Receipt generation (PDF) + share | P0 | Not Started | 1.7 | 2 days | Unassigned |
| 1.9 | Dashboard (today's snapshot, no AI insights yet) | P1 | Not Started | 1.6 | 2 days | Unassigned |
| 1.10 | Settings (business profile, tax, receipt template) | P1 | Not Started | 1.2 | 2 days | Unassigned |
| 1.11 | Staff accounts + invite flow | P1 | Not Started | 1.1 | 2 days | Unassigned |

## Phase 2 — Surfboard Client SDK ✅ Done

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 2.1 | Real HTTP request/auth implementation in `client/surfboardClient.base.js` (retry, timeout, request/response logging, request ID generation, auth-header placeholder — all real, all six domain clients inherit it for free) | P0 | Done | — | Claude |
| 2.2 | `SurfboardApiError` typed error + `errors/errorMapper.js` per [21_BACKEND_GUIDELINES.md § 9](21_BACKEND_GUIDELINES.md#9-error-handling); `SURFBOARD_ERROR`/502 added to `constants/` | P0 | Done | 2.1 | Claude |
| 2.3 | `mappers/baseMapper.js` contract scaffolding (`integrations/surfboard/mappers/`) — no domain mappers yet, those land with their owning phase | P0 | Done | 2.1 | Claude |
| 2.4 | `utils/webhookSignatureVerifier.js` — generic HMAC-SHA256 signature verification helper, not yet wired to a route (no webhook endpoint exists until Phase 9) | P0 | Done | 2.1 | Claude |
| 2.5 | Unit tests for the SDK (`backend/tests/integrations/surfboard/`) — base client, retry, timeout, request builder, response parser, error mapper, webhook verifier, auth placeholder, request ID, base mapper — 48 tests | P1 | Done | 2.1–2.4 | Claude |

**Note:** `models/` and `utils/requestBuilder.js`/`utils/responseParser.js`/`utils/requestId.js` and `middleware/{retry,timeout,auth,requestLogger,responseLogger}.middleware.js` were not separately itemized above (this task table predates the final file layout) but are all part of 2.1 — see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) for the full tree. No domain methods (`createMerchant()`, etc.) were added to any of the six domain client files — they remain placeholders inheriting a now-fully-working `request()`, per Phase 2's scope in [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md).

| 2.6 | Surfboard SDK authentication layer — strategy pattern (`auth/`, `provider/`, `cache/`, `middleware/authentication.middleware.js`) replacing the Phase 2 auth-header placeholder; API Key/Bearer/OAuth strategies, `AuthenticationManager`, cached+auto-refreshing `TokenProvider`, config validation, secure credential loading. **Not** the roadmap's Phase 3 below (that's Firebase identity, untouched). See [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3). | P0 | Done | 2.1 | Claude |

## Phase 3 — Client Authentication

> **Distinct from the 2026-07-29 Surfboard SDK authentication layer work (task 2.6 above).** That work was scoped entirely to how the *backend* authenticates outbound calls to *Surfboard's* API (`src/integrations/surfboard/auth/`) — a different, unrelated concern from this phase, which is Firebase identity for SurfPOS's own users. Approved and started 2026-07-29 — see [ADR-020](08_ARCHITECTURE_DECISIONS.md#adr-020--application-client-authentication-endpoint-shape-phase-3).

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 1.0 | Premium Flutter UI: design system (done) + 26 screens, one at a time (1/26 — Splash — done; see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) and `.claude/projectStatus.md`) | P0 | In Progress | 0.6 | ~10 days (26 screens) | Claude |
| 3.1 | Firebase Auth integration — email/password sign-up (`POST /auth/signup`), sign-in token exchange (`POST /auth/login`), sign-out (`POST /auth/logout`, refresh-token revocation), `authenticate` middleware (`src/middleware/auth.middleware.js`, delegates to `modules/auth/auth.service.js`). **Phone OTP not implemented** — out of scope for this pass, still open. | P0 | Done (email/password); phone OTP Not Started | P.1 | Claude |
| 3.2 | `GET /auth/me` resolving the caller's `users/{uid}` profile | P0 | Done | 3.1 | Claude |
| 3.3 | Staff invite flow (`POST /auth/staff-invite`) | P1 | Not Started | 3.1 | Unassigned |

## Phase 4 — Merchant Creation

> **Re-scoped 2026-07-29 from the original plan below.** Implemented as a `merchantApplications/{uid}` application-tracking resource (`POST/GET /merchant/applications`) rather than the originally-planned `POST /auth/register` orchestration — no Store creation, no `users/{uid}.merchantId` write in this pass. See [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4).
>
> **Wire format confirmed 2026-07-30** against the real Surfboard docs (previously a guess, per ADR-021's own caveat) — see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction). Store creation is now included in the same call (`controlFields.store`, required, not optional as Surfboard's own docs suggest — SurfPOS is in-store-only) — still no `users/{uid}.storeIds` write, same boundary as before. A real status-polling endpoint (`GET /merchant/applications/:id/status`) was added, backed by Surfboard's actual Check Application Status API. The Flutter onboarding wizard (`frontend/lib/features/merchant/`, previously empty) is built against this confirmed contract.

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 4.1 | `merchant.client.js` Merchant Creation call (`createMerchant()`) + `mappers/merchant.mapper.js` | P0 | Done, wire format confirmed | Phase 2 | Claude |
| 4.2 | `POST/GET /merchant/applications`, `GET /merchant/applications/:id` — `modules/merchant/{merchantApplication.service,merchantApplication.repository}.js`, Firebase-owned `merchantApplications/{uid}` tracking record | P0 | Done | 4.1 | Claude |
| 4.3 | `POST /auth/register` orchestration (Firebase Auth → Surfboard Merchant/Store creation → `users/{uid}.merchantId` reference write) — **original plan, not implemented this pass**, superseded in scope by 4.1/4.2; revisit if a single-call registration flow is still wanted | P1 | Not Started | 4.2, Phase 6 | Unassigned |
| 4.4 | `GET /merchant/applications/:id/status` — real Check Application Status polling, `merchant.client.js#getApplicationStatus()` | P0 | Done | 4.1 | Claude |
| 4.5 | Flutter Merchant Onboarding wizard (`features/merchant/`) — multi-step form, DI wiring, local status persistence, error handling | P0 | Done | 4.2, 4.4 | Claude |

## Phase 5 — Merchant Functions

> **Re-scoped 2026-07-29** from `GET/PATCH /merchants/:merchantId` (param-based) to `GET/PATCH /merchant` + `GET /merchant/status` (caller-scoped, no route param) — `merchantId` is resolved server-side from the caller's own `merchantApplications/{uid}.merchantId`, since `users/{uid}.merchantId` still doesn't exist (see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4)). See [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5).
>
> **Wire format confirmed 2026-07-30** — see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction). ADR-022's assumption that `GET /merchant/status` could be derived from `GET /merchant` is disproven (Fetch Merchant Details has no status field); it now polls the real Check Application Status endpoint via the caller's tracked `applicationId`. 3 real bugs fixed: missing `/partners/:partnerId` prefix, missing required `MERCHANT-ID` header, `PATCH` corrected to `PUT` (Surfboard's own method).

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 5.1 | `GET/PATCH /merchant` proxy endpoints (caller-scoped) + `GET /merchant/status` (now backed by the real status endpoint) | P0 | Done, wire format confirmed | Phase 4 | Claude |
| 5.2 | `merchant.mapper.js` extended (`toMerchantProfile`/`toMerchantUpdateWire`, Surfboard DTO → domain Merchant) | P0 | Done, wire format confirmed | 5.1 | Claude |

## Phase 6 — Store Capabilities

> **Re-scoped 2026-07-29**: implemented as caller-scoped CRUD (`POST/GET /stores`, `GET/PATCH /stores/:storeId`) rather than "default-store creation as part of registration" — Phase 4 never orchestrated Store creation (see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4)), so Store creation is its own explicit, standalone action here. Payment Methods (task 6.2) and multi-store UX flagging (6.3) are unchanged/still open. See [ADR-023](08_ARCHITECTURE_DECISIONS.md#adr-023--store-capabilities-local-registry--no-invented-list-endpoint-phase-6).

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 6.1 | `store.client.js` Store CRUD (`createStore`/`getStore`/`updateStore`) + `mappers/store.mapper.js`; `POST/GET /stores`, `GET/PATCH /stores/:storeId` | P0 | Done | Phase 2, Phase 5 | Claude |
| 6.2 | `GET/PATCH /stores/:storeId/payment-methods` (folded per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split)) | P0 | Not Started | 6.1 | Unassigned |
| 6.3 | Multi-store UX flagging (single-store Phase 1 UX) — largely moot now: `POST/GET /stores` already support multiple stores per merchant since Phase 4 never limited to one | P2 | Not Started | 6.1 | Unassigned |

## Phase 7 — Inventory

> **Implemented as a single `modules/inventory/` module** (`product.repository.js` + `stock.repository.js` + one `inventory.service.js`) rather than separate `products.*`/`inventory.*` files — see [ADR-024](08_ARCHITECTURE_DECISIONS.md#adr-024--inventory-management-in-memory-search--transactional-stock-phase-7). Barcode lookup (7.3) folded into `GET /inventory/products?barcode=` rather than a separate endpoint.

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 7.1 | Product catalog CRUD (`product.repository.js`, `inventory.service.js`) — search/filter/pagination/soft-delete | P0 | Done | Phase 6 | Claude |
| 7.2 | Inventory read/adjust endpoints (`stock.repository.js`, `inventory.service.js#adjustStock`) — transactional, never negative | P0 | Done | 7.1 | Claude |
| 7.3 | Barcode scanner backend lookup (`GET /inventory/products?barcode=`) | P0 | Done | 7.1 | Claude |
| 7.4 | Supplier CRUD (`suppliers.repository.js`, `suppliers.service.js` — new entity, see [20_DOMAIN_MODEL.md § 2.16](20_DOMAIN_MODEL.md#216-supplier--firebase-owned-new-in-this-pass)) — Product carries an optional `supplierId` reference field, but Supplier's own CRUD is **not** built this pass | P1 | Not Started | Phase 6 | Unassigned |

## Phase 8 — Billing

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 8.1 | Cart validation + Sale creation (`billing.service.js`, `sales.repository.js`) | P0 | Not Started | Phase 7 | Unassigned |
| 8.2 | Sale cancel/history endpoints | P1 | Not Started | 8.1 | Unassigned |
| 8.3 | Real-time sale-status strategy resolved and implemented (see [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) pending item) | P0 | Blocked | P.4 | Unassigned |

## Phase 9 — Payments

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 9.1 | `payment.client.js` payment intent creation | P0 | Not Started | Phase 2, Phase 8 | Unassigned |
| 9.2 | `POST /webhooks/surfboard` handler (signature verification, idempotency, Sale status update) | P0 | Not Started | 9.1 | Unassigned |
| 9.3 | `GET /payments/:paymentId` live proxy | P0 | Not Started | 9.1 | Unassigned |
| 9.4 | Tips configuration (`PATCH /stores/:storeId/tips-config`, folded per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split)) | P1 | Not Started | 9.1 | Unassigned |

## Phase 10 — Device Management

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 10.1 | `device.client.js` link/unlink/status | P0 | Not Started | Phase 2, Phase 6 | Unassigned |
| 10.2 | Device management endpoints + Settings UI hookup | P1 | Not Started | 10.1 | Unassigned |

## Phase 11 — Branding

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 11.1 | `branding.client.js` get/update | P1 | Not Started | Phase 2, Phase 5 | Unassigned |
| 11.2 | `GET/PATCH /merchants/:merchantId/branding` endpoints + Settings UI hookup | P1 | Not Started | 11.1 | Unassigned |

## Phase 12 — Analytics

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 12.1 | Analytics rollup job (daily/monthly precomputation over `sales`/`inventory`) | P1 | Not Started | Phase 8 | Unassigned |
| 12.2 | Dashboard/Reports endpoints | P1 | Not Started | 12.1 | Unassigned |
| 12.3 | Dashboard real-time strategy resolved (shares the Phase 8.3 open item) | P1 | Blocked | P.4 | Unassigned |

## Phase 13 — AI

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 13.1 | OCR integration | P0 | Not Started | P.3, P.4 (OCR provider choice) | Unassigned |
| 13.2 | OpenRouter structuring prompt + product/supplier matching | P0 | Not Started | 13.1, Phase 7.4 | Unassigned |
| 13.3 | Invoice scan review + confirm/reject endpoints; purchase Order creation on confirm | P0 | Not Started | 13.2 | Unassigned |
| 13.4 | AI business insights generation over Analytics rollups | P1 | Not Started | Phase 12, 13.2 | Unassigned |

## Future Scope (Not Scheduled)

See [01_PROJECT_OVERVIEW.md § 6](01_PROJECT_OVERVIEW.md#6-future-scope): multi-store UI, offline billing, customer loyalty/CRM, supplier portal, Flutter Web back-office, refunds/split payments, and other items beyond Phase 13.

---

**Next:** [11_CHANGELOG.md](11_CHANGELOG.md) — what has actually shipped, version by version.
