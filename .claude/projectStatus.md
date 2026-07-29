# Project Status

> Read after [project.md](project.md), before [decision.md](decision.md) and [memory.md](memory.md). See [project.md § Read these files next](project.md#read-these-files-next) for the full session-start reading order.
>
> **This file must be updated whenever new work is completed** — it is the live, authoritative snapshot of where the project actually is, as opposed to `docs/10_TASKS.md`'s longer-range roadmap.

---

## Current Phase

**Roadmap Phase 2 (Surfboard Client SDK) done** (see [docs/22_DEVELOPMENT_ROADMAP.md](../docs/22_DEVELOPMENT_ROADMAP.md)). The Surfboard SDK is real, tested infrastructure; no business module (auth/merchant/store/payments/inventory/billing/AI) has been touched — Phase 2 was explicitly scoped to SDK-only, and to stop for approval afterward.

## Current Sprint

No formal sprint cadence has been established yet. Work to date has proceeded as a sequence of discrete, explicitly-scoped requests (documentation → folder scaffold → `.claude/` knowledge base → backend foundation → infrastructure hardening → documentation realignment → Surfboard SDK) rather than time-boxed sprints.

## Progress Summary

Following the Surfboard-alignment documentation pass (Surfboard confirmed as system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods — see [decision.md § D-016](decision.md#d-016--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)), Phase 2 built the real HTTP infrastructure every future Surfboard-owned domain client will use: base client with retry/timeout/logging/auth-header-placeholder, request builder/response parser/request-ID utilities, a webhook signature verifier, a typed `SurfboardApiError` + error mapper, and a `BaseMapper` contract. All six domain clients (auth/merchant/payment/store/device/branding) now inherit a fully working `request()` but still have **zero domain methods** — Merchant/Store/Payment/Inventory/Billing/AI remain untouched, exactly as scoped. 48 new unit tests, full lint/format/test/build pipeline green, and a live manual verification (real Express app + mocked `fetch`) confirmed the whole pipeline — including error mapping through the real `error.middleware.js` — behaves correctly.

## Completed

- Full documentation system in `/docs` (18 files: overview, architecture, database design, API reference, features, UI/UX guide, coding rules, ADRs, prompt history, tasks, changelog, README, Claude context, developer guide, Surfboard integration, AI module, folder structure, contributing).
- Full enterprise repository folder structure (`frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/`, root config files) — placeholders (`README.md`/`.gitkeep`/stub entry points) only, except `backend/` (see next item).
- Reconciliation pass fixing stale `mobile/` → `frontend/` references across the doc set after the folder scaffold was created.
- Git repository initialized (independent of the user's home-directory mega-repo — see [memory.md](memory.md) for that history), pushed to `https://github.com/Gopi7104/SurfPOS-AI.git`.
- `.claude/` Claude knowledge base created (this file, `project.md`, `decision.md`, `workflow.md`, `commands.md`, `memory.md`).
- **Backend foundational scaffolding (task 0.7):** real `express`/`firebase-admin`/`zod`/`pino` dependencies installed; `config/index.js` (fail-fast env validation), `utils/{logger,errors,response,asyncHandler}.js`, `firebase/admin.js` (lazy init), `middleware/{auth,validate,error}.middleware.js`, `routes|controllers|services/health.*`, `app.js`/`server.js` — verified booting and `GET /health` responding locally with the standard envelope.
- ADR-010 (`zod`) and ADR-011 (`pino`) resolved — see [decision.md § D-012](decision.md#d-012--backend-validation-library-zod)/[D-013](decision.md#d-013--backend-logging-library-pino).
- **Backend infrastructure hardening:** ESLint flat config + Prettier + Husky pre-commit; `compression` + global `express-rate-limit` (health bypasses it); `backend/src/constants/`; `backend/src/types/`; `backend/src/integrations/surfboard/` placeholder client architecture (no real API calls); richer per-request logging; Vitest + Supertest suite (7 tests passing); `backend/src/docs/swagger/` folder skeleton; `.github/workflows/backend.yml` CI. ADR-012/ADR-013 resolved — see [decision.md § D-014](decision.md#d-014--lintformat-tooling-eslint-flat-config--prettier-not-airbnb-base)/[D-015](decision.md#d-015--srcintegrations-vs-srcmodules-split).
- **Surfboard-alignment documentation pass:** full rewrite of `docs/01–05, 07, 08, 10, 12, 13, 15, 17`; lighter updates to `docs/06, 09, 11, 14, 16, 18`; four new docs (`docs/19–22`). Surfboard confirmed as system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods (ADR-014/[D-016](decision.md#d-016--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)).
- **Roadmap Phase 2 — Surfboard Client SDK (this pass):** real `backend/src/integrations/surfboard/{client,middleware,models,mappers,utils,errors}/` — base HTTP client (retry/timeout/logging/auth-placeholder), request builder/response parser/request-ID utils, webhook HMAC signature verifier, `SurfboardApiError` + error mapper, `BaseMapper` contract. All six domain clients inherit a working `request()`; zero domain methods added. 48 new tests, full pipeline green. ADR-018 recorded — see [decision.md § D-019](decision.md#d-019--surfboard-sdk-implementation-choices-native-fetch-retrytimeout-defaults-placeholder-auth--webhook-schemes).

## In Progress

- Nothing mid-flight — Phase 2 is complete and it's a stopping point: waiting for user approval before Phase 3 (Client Authentication).

## Not Started

- Everything in `docs/22_DEVELOPMENT_ROADMAP.md` Phase 3 (Client Authentication) onward — **explicitly on hold pending user approval**, not just unstarted.
- Prerequisites: Firebase project creation, Surfboard sandbox credentials + official API docs, Gemini API key.
- Remaining open technical decisions: OCR provider, production font, real-time client strategy (see [decision.md](decision.md), `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`).
- Confirming the SDK's placeholder auth-header scheme and webhook signature scheme against real Surfboard documentation.

## Blockers

- **Hard blocker: waiting for explicit user approval before Phase 3 (Client Authentication) or any later phase** — this was the explicit closing instruction of this pass.
- Phase 4 (Merchant Creation) onward will additionally need a real Firebase project and Surfboard sandbox credentials.

## Known Issues

1. **Two technical decisions remain open**: OCR provider, production font — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`. Real-time client strategy (polling vs. push/streaming) is also open.
2. **Surfboard Payments' exact wire-level API surface is unconfirmed** against official documentation — the SDK's auth-header scheme and webhook signature scheme are explicit, isolated placeholders (see ADR-018) pending confirmation.
3. **Sweden/SEK propagation:** only `docs/01_PROJECT_OVERVIEW.md`/`docs/03_DATABASE_DESIGN.md` were corrected as a side effect of full rewrites — not an exhaustive pass.
4. **Branch/commit hygiene:** unresolved per-person branch situation (`main`, `velan`, `gopi`) — see [memory.md](memory.md).
5. **`npm audit` shows moderate/high advisories transitively inside `firebase-admin`'s own dependency tree** — not fixable from this repo without a worse downgrade.

## Current Priorities

1. **Get explicit user approval before starting Phase 3 (Client Authentication)** — the single blocking priority right now.
2. Once approved: Phase 3 (Client Authentication) per `docs/22_DEVELOPMENT_ROADMAP.md`.
3. Provision Firebase project, Surfboard sandbox credentials + official API docs, Gemini API key.
4. Decide and record remaining technical decisions (OCR provider, font, real-time client strategy) in [decision.md](decision.md).
5. Agree a branch/merge strategy for `main` / `velan` / `gopi`.

## Next Tasks

Per `docs/10_TASKS.md`:

- Phase 3 (Client Authentication) — 3.1 Firebase Auth integration, 3.2 `GET /auth/me`, 3.3 staff invite flow.
- Prerequisites (P.1–P.4) — Firebase project, Surfboard sandbox + docs, Gemini key, real-time strategy decision — still open, block Phase 4+.

## Upcoming Milestones

Per `docs/22_DEVELOPMENT_ROADMAP.md` — Phase 1 ✅ → Phase 2 ✅ → Phase 3 (Client Authentication, next) → Phase 4 (Merchant Creation) → Phase 5 (Merchant Functions) → Phase 6 (Store Capabilities) → Phase 7 (Inventory) → Phase 8 (Billing) → Phase 9 (Payments) → Phase 10 (Device Management) → Phase 11 (Branding) → Phase 12 (Analytics) → Phase 13 (AI).

## Recently Modified Files

- New: `backend/src/integrations/surfboard/{client/{surfboardClient.base,surfboardConfig},middleware/{retry,timeout,auth,requestLogger,responseLogger}.middleware,models/{environment,requestOptions,response},mappers/baseMapper,utils/{requestId,requestBuilder,responseParser,webhookSignatureVerifier},errors/{surfboardApiError,errorMapper}}.js`; `backend/tests/integrations/surfboard/` (9 files, 48 tests).
- Modified: `backend/src/integrations/surfboard/{auth,merchant,payment,store,device,branding}.client.js` (require path only), `index.js`, `README.md`; `backend/src/constants/{httpStatus,errorCodes,messages}.js`.
- Removed: old root-level `surfboardClient.base.js` placeholder (moved into `client/`).
- Docs: `docs/10_TASKS.md`, `docs/22_DEVELOPMENT_ROADMAP.md`, `docs/13_CLAUDE_CONTEXT.md`, `docs/08_ARCHITECTURE_DECISIONS.md` (ADR-018), `docs/11_CHANGELOG.md`, `docs/09_PROMPT_HISTORY.md`, `.claude/{projectStatus,decision}.md` (this file + decision.md D-019).
- **No file under `backend/src/modules/`, `backend/src/controllers/`, `backend/src/routes/`, or `backend/src/firebase/` was touched this pass.**

## Notes for the Next Claude Session

- Read files in the order specified in [project.md § Read these files next](project.md#read-these-files-next) before touching any code.
- **Do not write any application code for Phase 3 (Client Authentication) or later until the user explicitly approves.** This was the explicit closing instruction of this pass.
- **The single most important standing rule:** never persist a duplicate of a Surfboard-owned object (Merchant/Store/Device/Payment/Branding/Tips/Payment Methods) in Firebase. Check [docs/20_DOMAIN_MODEL.md § 1](../docs/20_DOMAIN_MODEL.md#1-the-ownership-principle) before adding any new Firebase field.
- The Surfboard SDK (`backend/src/integrations/surfboard/`) is now real and tested — its six domain clients have zero domain methods though. Adding `createMerchant()` etc. is Phase 4+ work, not something to backfill opportunistically.
- The SDK's auth-header scheme (`middleware/auth.middleware.js`) and webhook signature scheme (`utils/webhookSignatureVerifier.js`) are explicit placeholders (HMAC-SHA256, Bearer token) — confirm against real Surfboard docs before relying on them in a real integration.
- Backend foundational + infrastructure code (`backend/src/{config,utils,firebase,middleware,routes,controllers,services,constants,types,integrations}`) is real; every business-domain module (`src/modules/*`) is still a placeholder.
- Check current git branch and status before assuming which commit's content is on disk (see [memory.md](memory.md)).
- Only create git commits or push when explicitly asked.
