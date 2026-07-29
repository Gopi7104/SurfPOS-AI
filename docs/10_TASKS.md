# 10 — Tasks / Roadmap

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file, including the old Phase 0/1/2/3 structure.** Related: [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) (the authoritative phase order and *why*, read that first), [05_FEATURES.md](05_FEATURES.md) (what each task builds), [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (decisions each task depends on), [11_CHANGELOG.md](11_CHANGELOG.md) (what's actually shipped).

---

## How to Use This File

Every task has: **Priority** (P0 = blocking/critical, P1 = important, P2 = nice-to-have), **Status** (`Not Started` / `In Progress` / `Blocked` / `Done`), **Dependencies**, **Owner** (`Unassigned` until claimed). Phase numbers/names match [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) exactly — if they ever disagree, that file wins.

---

## Prerequisites (block Phase 2)

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| P.1 | Firebase project setup (Auth, RTDB, Storage) + `database.rules.json` skeleton (application data only) | P0 | Not Started | — | Unassigned |
| P.2 | Surfboard Payments sandbox/developer account + API credentials + official API documentation | P0 | Not Started | — | Unassigned |
| P.3 | Gemini API key provisioning (blocks Phase 13 only) | P0 | Not Started | — | Unassigned |
| P.4 | Resolve remaining [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) items relevant to near-term phases (real-time client strategy — blocks Phase 8/12) | P0 | Not Started | — | Unassigned |

## Phase 1 — Backend Foundation ✅ Done

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 1.1 | Express app bootstrap, env config, logger, Firebase Admin SDK init, auth/validation/error middleware, response helper, `GET /health` | P0 | Done | — | Claude |
| 1.2 | Infrastructure hardening: ESLint/Prettier/Husky, compression + rate limiting, `constants/`/`types/` layers, placeholder Surfboard integration clients, richer logging, tests, CI | P0 | Done | 1.1 | Claude |
| 1.3 | Documentation realignment to Surfboard-as-system-of-record architecture | P0 | Done | — | Claude |

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

> **Unaffected by the 2026-07-29 Surfboard SDK authentication layer work (task 2.6 above).** That work was scoped entirely to how the *backend* authenticates outbound calls to *Surfboard's* API (`src/integrations/surfboard/auth/`) — a different, unrelated concern from this phase, which is Firebase identity for SurfPOS's own users (sign-up/sign-in, `GET /auth/me`, staff invites). This phase remains `Not Started` and still requires explicit user approval before starting, per [13_CLAUDE_CONTEXT.md § 5](13_CLAUDE_CONTEXT.md).

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 3.1 | Firebase Auth integration (sign-up/sign-in, email + phone OTP) | P0 | Not Started | P.1 | Unassigned |
| 3.2 | `GET /auth/me` resolving `users/{uid}` → `merchantId`/`storeIds` references | P0 | Not Started | 3.1 | Unassigned |
| 3.3 | Staff invite flow (`POST /auth/staff-invite`) | P1 | Not Started | 3.1 | Unassigned |

## Phase 4 — Merchant Creation

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 4.1 | `merchant.client.js` Merchant Creation call | P0 | Not Started | Phase 2 | Unassigned |
| 4.2 | `POST /auth/register` orchestration (Firebase Auth → Surfboard Merchant/Store creation → `users/{uid}` reference write) | P0 | Not Started | 4.1, 3.1 | Unassigned |

## Phase 5 — Merchant Functions

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 5.1 | `GET/PATCH /merchants/:merchantId` proxy endpoints | P0 | Not Started | Phase 4 | Unassigned |
| 5.2 | `merchant.mapper.js` (Surfboard DTO → domain Merchant) | P0 | Not Started | 5.1 | Unassigned |

## Phase 6 — Store Capabilities

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 6.1 | `store.client.js` Store CRUD + default-store creation (part of Phase 4 registration flow) | P0 | Not Started | Phase 2 | Unassigned |
| 6.2 | `GET/PATCH /stores/:storeId/payment-methods` (folded per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split)) | P0 | Not Started | 6.1 | Unassigned |
| 6.3 | `GET/POST /stores` multi-store endpoints (flagged off for single-store Phase 1 UX) | P1 | Not Started | 6.1 | Unassigned |

## Phase 7 — Inventory

| # | Task | Priority | Status | Dependencies | Owner |
|---|---|---|---|---|---|
| 7.1 | Product catalog CRUD (`products.repository.js`, `products.service.js`) | P0 | Not Started | Phase 6 | Unassigned |
| 7.2 | Inventory read/adjust endpoints (`inventory.repository.js`, `inventory.service.js`) | P0 | Not Started | 7.1 | Unassigned |
| 7.3 | Barcode scanner backend lookup (`GET /products?barcode=`) | P0 | Not Started | 7.1 | Unassigned |
| 7.4 | Supplier CRUD (`suppliers.repository.js`, `suppliers.service.js` — new entity, see [20_DOMAIN_MODEL.md § 2.16](20_DOMAIN_MODEL.md#216-supplier--firebase-owned-new-in-this-pass)) | P1 | Not Started | Phase 6 | Unassigned |

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
| 13.2 | Gemini structuring prompt + product/supplier matching | P0 | Not Started | 13.1, Phase 7.4 | Unassigned |
| 13.3 | Invoice scan review + confirm/reject endpoints; purchase Order creation on confirm | P0 | Not Started | 13.2 | Unassigned |
| 13.4 | AI business insights generation over Analytics rollups | P1 | Not Started | Phase 12, 13.2 | Unassigned |

## Future Scope (Not Scheduled)

See [01_PROJECT_OVERVIEW.md § 6](01_PROJECT_OVERVIEW.md#6-future-scope): multi-store UI, offline billing, customer loyalty/CRM, supplier portal, Flutter Web back-office, refunds/split payments, and other items beyond Phase 13.

---

**Next:** [11_CHANGELOG.md](11_CHANGELOG.md) — what has actually shipped, version by version.
