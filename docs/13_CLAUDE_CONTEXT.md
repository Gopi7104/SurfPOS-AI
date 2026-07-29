# 13 — Claude Context (Read This First)

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** **Every Claude Code session working on this repository must read this file before doing anything else.** It is the single entry point into the rest of the documentation. If something here conflicts with another doc file, the more detailed file wins and this file should be updated to match.

---

## 1. Project Summary

**SurfPOS AI** is a mobile-first, AI-powered cloud POS platform for small retailers (Sweden, initial market), integrated with **Surfboard Payments**. Flutter frontend (talks only to the backend — no direct Firebase/Surfboard access), Node.js/Express backend, **two systems of record**: Surfboard owns Merchant/Store/Device/Payment/Branding/Tips/Payment Methods; Firebase owns application data (Inventory/Product/Sale/Order/InvoiceScan/Receipt/Analytics/Settings/Supplier/User). Full detail: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md).

## 2. Architecture Summary

- The Flutter app talks **only** to the Node/Express backend — there is no direct Flutter↔Firebase or Flutter↔Surfboard path (a change from earlier plans — see [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)).
- The backend is layered `routes → controllers → services → { repositories (Firebase) | integration clients (Surfboard) }` — full contract in [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).
- **Never duplicate a Surfboard-owned object in Firebase.** If you're about to add a field that copies a Surfboard business fact, stop — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle).
- Full detail: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), domain model: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), Firebase schema: [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), Surfboard workflows: [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md), API: [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md).

## 3. Current Status

**As of 2026-07-29: the frontend has real, first application code.** Documentation and repository scaffolding are complete (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)), and a `.claude/` Claude-specific knowledge base now sits alongside `/docs` (read it first — see `.claude/project.md`). Beyond that, the frontend now has a complete custom design system and reusable widget library (`frontend/lib/app/themes/`, `frontend/lib/core/widgets/`) and the first of 26 planned screens (Splash). The backend, Firebase project, and Surfboard/Gemini integrations remain entirely unimplemented. See [11_CHANGELOG.md](11_CHANGELOG.md) and `.claude/projectStatus.md` for the authoritative "what's actually built" record — trust those over assumptions.
**As of 2026-07-29: Phases 2 through 5 are all implemented, on top of the realigned documentation.** The Surfboard SDK (`backend/src/integrations/surfboard/{client,middleware,models,mappers,utils,errors,auth,provider,cache}/`) is real, working infrastructure — every domain client inherits a fully functional `request()` with retry, timeout, a pluggable strategy-pattern auth layer (see [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3)), request IDs, and logging. **`merchant.client.js` now has three real domain methods** (`createMerchant()`, `getMerchant()`, `updateMerchant()`) — every other domain client (payment/store/device/branding) still has none. **Roadmap Phase 3 — Application Client Authentication** (Firebase identity, `backend/src/modules/auth/`, `POST /auth/{signup,login,logout}`, `GET /auth/me`) is implemented for email/password — see [ADR-020](08_ARCHITECTURE_DECISIONS.md#adr-020--application-client-authentication-endpoint-shape-phase-3). **Roadmap Phase 4 — Merchant Creation** was re-scoped by explicit instruction to a standalone `merchantApplications/{uid}` tracking resource (`POST/GET /merchant/applications`, `GET /merchant/applications/:id`) rather than the originally-documented `POST /auth/register` orchestration — no Store creation, no `users/{uid}.merchantId` write yet, see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4). **Roadmap Phase 5 — Merchant Functions** (`GET/PATCH /merchant`, `GET /merchant/status`) is implemented, caller-scoped with no `:merchantId` param — `merchantId` is resolved from the caller's own `merchantApplications/{uid}.merchantId` rather than a `users/{uid}` field that still doesn't exist, see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5). A real bug was found and fixed during Phase 4: `SurfboardBaseClient` eagerly constructed its `AuthenticationManager` (crashing on require without `SURFBOARD_API_KEY` set) — now a lazy getter. Phone/OTP sign-in and the staff-invite flow (task 3.3) remain not implemented. 172 unit/route tests now cover the backend. See [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) for the phase plan and [11_CHANGELOG.md](11_CHANGELOG.md) for the authoritative "what's actually built" record.

## 4. Completed Work

- Full documentation system (22 files in `/docs`), realigned to Surfboard-as-system-of-record (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) for the pass that did this).
- Full enterprise repository folder structure scaffolded.
- Backend foundational scaffolding + infrastructure hardening (Roadmap Phase 1).
- **Roadmap Phase 2 — Surfboard Client SDK:** real HTTP client (`client/surfboardClient.base.js`, `client/surfboardConfig.js`), retry/timeout/logging middleware, request builder/parser/ID utils, a webhook signature verifier, `SurfboardApiError` + error mapper, and a `BaseMapper` contract for future domain mappers. All placeholder-only at the domain-method level — see [10_TASKS.md](10_TASKS.md) Phase 2 for the full breakdown.
- **Phase 2 extension — Surfboard SDK Authentication Layer (task 2.6, not Roadmap Phase 3):** the auth-header placeholder is now a real strategy-pattern implementation (API Key/Bearer/OAuth, `AuthenticationManager`, `TokenProvider`+`TokenCache`) under `integrations/surfboard/{auth,provider,cache}/`. See [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3).
- **Roadmap Phase 3 — Application Client Authentication (email/password):** `backend/src/modules/auth/{auth.service,users.repository}.js`, `POST /auth/signup`/`POST /auth/login`/`POST /auth/logout`/`GET /auth/me`, `middleware/auth.middleware.js` refactored to share token verification with the login flow. No Merchant/Store/Surfboard record created — see [ADR-020](08_ARCHITECTURE_DECISIONS.md#adr-020--application-client-authentication-endpoint-shape-phase-3). Phone/OTP and staff-invite (3.3) not implemented.
- **Roadmap Phase 4 — Merchant Creation (re-scoped):** `merchant.client.js#createMerchant()` + `mappers/merchant.mapper.js`, `backend/src/modules/merchant/{merchantApplication.service,merchantApplication.repository}.js`, `POST/GET /merchant/applications`, `GET /merchant/applications/:id`, new Firebase-owned `merchantApplications/{uid}` entity. No Store created, no `users/{uid}.merchantId` write — see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4).
- **Roadmap Phase 5 — Merchant Functions:** `merchant.client.js#getMerchant()`/`#updateMerchant()` + mapper additions, `backend/src/modules/merchant/{merchant.service,merchant.repository}.js`, `GET/PATCH /merchant`, `GET /merchant/status`. `merchantId` resolved from `merchantApplications/{uid}`; `merchant.repository.js` composes `merchantApplication.repository.js` rather than touching Firebase directly — see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5).
- `.claude/` Claude Code knowledge base (project.md, decision.md, projectStatus.md, workflow.md, commands.md, memory.md) — read this **before** this file in a fresh session, per `.claude/project.md`'s reading order.
- Frontend design system + reusable widget library (see `.claude/projectStatus.md § Completed` for the full file list) and the Splash screen — the first of 26 planned screens in a premium-UI rebuild of the frontend, built one screen at a time per explicit user instruction.

## 5. Pending Work

Everything in [10_TASKS.md](10_TASKS.md) / [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md), starting with:
- **Get explicit user approval before starting Phase 6 (Store Capabilities)** — this session was explicitly scoped to stop after Phase 5 (Merchant Functions) and wait for approval.
- Prerequisites still open: a real Firebase project (P.1 — Phases 3–5's code is logically tested against fakes, but has **not** been exercised against a real Firebase Auth/RTDB instance yet), Surfboard sandbox credentials + official API docs (P.2 — every `merchant.client.js` method's wire format is still unconfirmed, see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4)/[ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5)), Gemini API key (see [22_DEVELOPMENT_ROADMAP.md § Prerequisites](22_DEVELOPMENT_ROADMAP.md#prerequisites-block-phase-2-not-numbered-as-their-own-phase)).
- Resolve the still-open [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) items: OCR provider, production font, Gemini-insights storage location, exact Surfboard wire-level specifics, real-time client strategy.
- Remaining Phase 3 scope not yet done: phone/OTP sign-in, staff-invite flow (task 3.3).
- `POST /auth/register`'s originally-planned full orchestration (Firebase + Surfboard Merchant + Store + `users/{uid}.merchantId` in one call) remains undecided/unscheduled — see task 4.3 in [10_TASKS.md](10_TASKS.md).
- Then Phase 6 (Store Capabilities) onward, in the exact order in [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) — **do not skip ahead to a later phase's feature.**

## 6. Known Issues

- `npm audit` reports moderate/high advisories transitively inside `firebase-admin`'s own Google Cloud client dependencies — not fixable from this repo without a downgrade that would be worse; track upstream.
- Sweden/SEK vs. earlier India/INR framing: this pass's full rewrites of [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md) and [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) already corrected their India-specific examples to Sweden/SEK/`sv-SE` as a side effect of being fully rewritten — but check other docs (e.g. [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) examples) before assuming the whole set is clean; this was not an exhaustive Sweden/SEK propagation pass, just an incidental correction where this pass's rewrites happened to touch it.
- Real-time client strategy is now an open item (see § 5) — a real, new gap created by removing direct Flutter↔Firebase access, not an oversight to silently patch.

## 7. Current Priorities

1. **Wait for explicit user approval before starting Phase 6 (Store Capabilities) or any later phase** — this session was explicitly scoped to stop and wait once Phase 5 (Merchant Functions) was complete. Do not proceed just because Phase 5 tested clean.
2. Once approved: Phase 6 (Store Capabilities — default Store creation, Store profile proxy, Payment Methods) is next in roadmap order — see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md). Note it likely needs the same "no `users/{uid}` reference yet" problem Phase 5 solved (see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5)) — a Store will need to reference a `merchantId` resolved the same way, and its own reference likely belongs on `merchantApplications/{uid}` or a new node, not `users/{uid}.storeIds` (still unwritten).
3. Keep this file, [10_TASKS.md](10_TASKS.md), [11_CHANGELOG.md](11_CHANGELOG.md), and [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) updated as living documents.

## 8. Coding Rules (Summary — full detail in [07_CODING_RULES.md](07_CODING_RULES.md), [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md))

- Layered Node structure: `routes → controllers → services → { repositories | integration clients }` — a Service never reaches into another module's Repository/Integration Client directly.
- **Never persist a duplicate of a Surfboard-owned object in Firebase** — this is the single most important new rule from this pass.
- Small functions (≤30 lines), small components, no god-files.
- No comments except non-obvious *why*.
- Inventory is only ever mutated through `inventory.service.js`; sale totals only in `billing.service.js`.
- Every backend endpoint validates input, verifies the Firebase ID token, and re-checks `merchantId`/`storeId`/`role` **reference** ownership before acting.
- No secrets in the Flutter app or in git.

## 9. Development Philosophy

- **AI proposes, humans confirm** for anything that changes money or stock.
- **The backend is the sole gatekeeper to both systems of record** — the client never talks to Firebase or Surfboard directly (new framing this pass, see § 2).
- **Never duplicate a Surfboard object** — the single most important addition to the philosophy this pass; see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle).
- **Mobile-first, one-handed, fast.**
- **No local server, no local database for the merchant.**
- **Documentation is maintained, not archived.** [10_TASKS.md](10_TASKS.md), [11_CHANGELOG.md](11_CHANGELOG.md), [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md), and [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) must be updated as part of any non-trivial change.

## 10. Important Notes

- **This documentation set is now the single source of truth for the entire project** — this was an explicit instruction for this pass. Any future code that contradicts it (e.g. a `merchants/{merchantId}` Firebase write) is a bug, not an alternate valid approach.
- Surfboard's exact wire-level API surface (endpoint names, auth mechanism, payload field names) is **still not confirmed** against official docs — only the *ownership model* (which entities Surfboard owns) is now confirmed. See [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) accuracy note.
- Real-time client strategy (polling vs. push/streaming) is an open item — see § 5/6.
- Be careful with git operations — confirm scope before staging/committing, never run broad commands like `git add -A`. Only commit/push when explicitly asked.

## 11. How to Continue Development

1. Read this file, then [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) and [02_ARCHITECTURE.md](02_ARCHITECTURE.md) for the two-systems-of-record architecture.
2. Check [10_TASKS.md](10_TASKS.md)/[22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) for the next unclaimed task in phase order, and [11_CHANGELOG.md](11_CHANGELOG.md)/`git log` for what's actually already built.
3. Before implementing, check whether the task touches an open [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) item.
4. Follow [07_CODING_RULES.md](07_CODING_RULES.md) and [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) exactly — consult [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) before adding any new field or endpoint, specifically to check whether it belongs in Firebase or should instead be a live Surfboard call.
5. When done: update [10_TASKS.md](10_TASKS.md) status, add an [11_CHANGELOG.md](11_CHANGELOG.md) entry, add a [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) entry, and add/update an ADR in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) if a non-trivial decision was made.

---

**See also:** [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) for hands-on setup, [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) for the backend layering contract.
