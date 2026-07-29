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

**As of 2026-07-29: Phase 2 (Surfboard Client SDK) is implemented, and its deferred authentication placeholder has now been completed with a real, pluggable auth layer — both on top of the realigned documentation.** The Surfboard SDK (`backend/src/integrations/surfboard/{client,middleware,models,mappers,utils,errors}/`) is real, working infrastructure — every domain client (auth/merchant/payment/store/device/branding) now inherits a fully functional `request()` with retry, timeout, auth headers, request IDs, and logging — but **no domain method exists yet** (no `createMerchant()`, no `createPaymentIntent()`, etc.) and **no business module, controller, route, or Firebase access was added**. The auth-header attachment Phase 2 left as a single hardcoded placeholder is now a strategy-pattern abstraction (`backend/src/integrations/surfboard/{auth,provider,cache}/` — API Key/Bearer/OAuth strategies, `AuthenticationManager`, cached auto-refreshing `TokenProvider`) — see [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3). **This is distinct from [Roadmap Phase 3 — Client Authentication](22_DEVELOPMENT_ROADMAP.md#phase-3--client-authentication) (Firebase merchant/staff sign-in), which remains untouched, `Not Started`, and still gated on approval — see § 5/7 below.** 97 unit tests now cover the SDK against a mocked HTTP layer. See [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) for the phase plan and [11_CHANGELOG.md](11_CHANGELOG.md) for the authoritative "what's actually built" record.

## 4. Completed Work

- Full documentation system (22 files in `/docs`), realigned to Surfboard-as-system-of-record (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) for the pass that did this).
- Full enterprise repository folder structure scaffolded.
- Backend foundational scaffolding + infrastructure hardening (Roadmap Phase 1).
- **Roadmap Phase 2 — Surfboard Client SDK:** real HTTP client (`client/surfboardClient.base.js`, `client/surfboardConfig.js`), retry/timeout/logging middleware, request builder/parser/ID utils, a webhook signature verifier, `SurfboardApiError` + error mapper, and a `BaseMapper` contract for future domain mappers. All placeholder-only at the domain-method level — see [10_TASKS.md](10_TASKS.md) Phase 2 for the full breakdown.
- **Phase 2 extension — Surfboard SDK Authentication Layer (task 2.6, not Roadmap Phase 3):** the auth-header placeholder is now a real strategy-pattern implementation (API Key/Bearer/OAuth, `AuthenticationManager`, `TokenProvider`+`TokenCache`) under `integrations/surfboard/{auth,provider,cache}/`. See [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3).

## 5. Pending Work

Everything in [10_TASKS.md](10_TASKS.md) / [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md), starting with:
- **Get explicit user approval before starting Phase 3 (Client Authentication)** — Phase 2 was explicitly scoped to stop and wait for approval once complete.
- Prerequisites still open: Firebase project, Surfboard sandbox credentials + official API docs, Gemini API key (see [22_DEVELOPMENT_ROADMAP.md § Prerequisites](22_DEVELOPMENT_ROADMAP.md#prerequisites-block-phase-2-not-numbered-as-their-own-phase)) — Phase 2's SDK shape didn't need real credentials to build/test, but Phase 3+ will need the Firebase project specifically, and confirming the SDK's placeholder base URL/auth scheme/webhook signature scheme needs real Surfboard docs.
- Resolve the still-open [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) items: OCR provider, production font, Gemini-insights storage location, exact Surfboard wire-level specifics, real-time client strategy.
- Then Phase 3 (Client Authentication) onward, in the exact order in [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) — **do not skip ahead to a later phase's feature.**

## 6. Known Issues

- `npm audit` reports moderate/high advisories transitively inside `firebase-admin`'s own Google Cloud client dependencies — not fixable from this repo without a downgrade that would be worse; track upstream.
- Sweden/SEK vs. earlier India/INR framing: this pass's full rewrites of [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md) and [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) already corrected their India-specific examples to Sweden/SEK/`sv-SE` as a side effect of being fully rewritten — but check other docs (e.g. [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) examples) before assuming the whole set is clean; this was not an exhaustive Sweden/SEK propagation pass, just an incidental correction where this pass's rewrites happened to touch it.
- Real-time client strategy is now an open item (see § 5) — a real, new gap created by removing direct Flutter↔Firebase access, not an oversight to silently patch.

## 7. Current Priorities

1. **Wait for explicit user approval before starting Phase 3 (Client Authentication) or any later phase** — Phase 2 was explicitly scoped to stop and wait once the SDK was complete. Do not proceed just because Phase 2 tested clean.
2. Once approved: Phase 3 (Client Authentication) is next — see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md).
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
