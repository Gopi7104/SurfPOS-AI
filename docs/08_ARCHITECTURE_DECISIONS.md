# 08 — Architecture Decision Records (ADRs)

> This file is the permanent decision log. **Every future significant decision — not just the founding ones below — must be appended here**, never overwritten. **Amended during the Surfboard-alignment documentation pass** (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md)): ADR-014/015/016 added, ADR-002/ADR-008 annotated to reflect the Surfboard-as-system-of-record decision — their original entries are kept intact per the "never edit history away" rule below, with a clarifying note on each. Related: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md).

**Format:** each entry has a Status, Context, Decision, Consequences, and Revisit trigger. Status is one of `Proposed`, `Accepted`, `Superseded by ADR-00X`, or `Accepted (amended)` — the last used when a decision is still substantially correct but a later ADR narrows/clarifies its scope without reversing it.

---

## ADR-001 — Why Flutter for the frontend

- **Status:** Accepted
- **Context:** SurfPOS AI must ship for both Android and iOS, mobile-first, with a UI-heavy feature set (scanner, camera capture) and a small initial engineering team.
- **Decision:** Use Flutter (Dart) as the single frontend codebase for Android and iOS.
- **Consequences:** One codebase instead of two native ones; strong first-party camera/barcode plugin ecosystem. Trade-off: Dart is a smaller hiring pool than JS/TS or Kotlin/Swift alone.
- **Revisit if:** the product needs deep native-only capability Flutter can't reach performantly, or a web/desktop client becomes priority.

## ADR-002 — Why Firebase (Auth, Realtime Database, Storage) for application data

- **Status:** Accepted (amended — see note below)
- **Context:** Target customers cannot manage servers, backups, or database administration.
- **Decision:** Use Firebase Authentication, Realtime Database, and Storage for **application data and identity** — no separate SQL/NoSQL database for that data.
- **Consequences:** Zero database-ops burden for application data; tight Firebase Auth ↔ RTDB Security Rules integration. Trade-off: RTDB has no complex/relational queries.
- **Amendment (2026-07-29, Surfboard-alignment pass):** The original wording of this ADR described Firebase as "the entire data platform" for SurfPOS AI. That is no longer accurate: Firebase is the data platform for **application data only** (inventory, catalog, sales, analytics, receipts, AI pipeline, settings — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods are owned by Surfboard, not Firebase — see [ADR-014](#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods) below. Authentication and Storage remain fully accurate as originally decided; only the Realtime-Database-as-sole-datastore framing is narrowed.
- **Revisit if:** query complexity outgrows what denormalization can reasonably support, or RTDB throughput becomes a bottleneck.

## ADR-003 — Why Node.js + Express for the backend

- **Status:** Accepted
- **Context:** The backend's job is orchestration (Firebase Admin SDK, Gemini API, OCR, and now a much larger Surfboard integration surface) rather than heavy compute.
- **Decision:** Node.js + Express.js as a thin, stateless REST API layer, and — per this pass — the **sole gatekeeper** to both Firebase and Surfboard (see [02_ARCHITECTURE.md § 1](02_ARCHITECTURE.md#1-system-architecture-high-level)).
- **Consequences:** Naturally async, well suited to orchestrating multiple external calls per request. Trade-off: not ideal for CPU-heavy work.
- **Revisit if:** a CPU-bound workload needs to move in-process.

## ADR-004 — Why AI OCR + Gemini for invoice scanning

- **Status:** Accepted — unaffected by the Surfboard-alignment pass (the AI pipeline is entirely Firebase-owned data, see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)).
- **Context/Decision/Consequences:** unchanged from the founding decision — see [16_AI_MODULE.md](16_AI_MODULE.md) for current detail.
- **Revisit if:** extraction accuracy is measured post-launch to be reliably high enough for an opt-in auto-confirm mode.

## ADR-005 — Why smartphone-only POS (no dedicated terminal/hardware requirement)

- **Status:** Accepted
- **Context:** Dedicated POS hardware is a major upfront cost barrier for the target small-retailer customer.
- **Decision:** The phone's own camera is the barcode/invoice scanner; payment acceptance uses whichever Surfboard-supported method works from the phone or a Surfboard-linked device.
- **Consequences:** Zero-hardware onboarding. **Reinforced by this pass:** since Surfboard now owns Device identity outright (see [20_DOMAIN_MODEL.md § 2.3](20_DOMAIN_MODEL.md#23-device--surfboard-owned)), SurfPOS never needs its own device-management data layer — it's a straight proxy to Surfboard's Device API (see [19_SURFBOARD_WORKFLOWS.md § 3](19_SURFBOARD_WORKFLOWS.md#3-device-lifecycle)).
- **Revisit if:** optional hardware add-ons are prioritized.

## ADR-006 — Why cloud architecture (no local/offline-first-by-default design)

- **Status:** Accepted
- **Context/Decision:** unchanged — Firebase RTDB (application data) and Surfboard (its seven owned entities) are both cloud systems; the backend is stateless and cloud-hosted.
- **Consequences:** Checkout now genuinely requires connectivity to **two** external systems (Firebase for the Sale write, Surfboard for the Payment) — a stricter version of the original "checkout requires connectivity" constraint, not a new one.
- **Revisit if:** merchant feedback shows connectivity gaps are a frequent blocker at the point of sale.

## ADR-007 — State management: Riverpod (Flutter)

- **Status:** Proposed (unaffected by this pass — confirm before Phase 3+ Flutter screens are built)
- **Context/Decision/Consequences:** unchanged.

## ADR-008 — Multi-tenant data model from day one, multi-store UI deferred

- **Status:** Accepted (amended — see note below)
- **Context:** Retrofitting a multi-tenant/multi-store schema after data exists is expensive and risky.
- **Decision:** Every Firebase application-data node is keyed/scoped by `merchantId` and, where relevant, `storeId`.
- **Amendment (2026-07-29, Surfboard-alignment pass):** `merchantId`/`storeId` are now **Surfboard-issued IDs** used as foreign-key references, not locally-generated Firebase push IDs as originally implied (Merchant/Store no longer have a Firebase-side record to generate an ID from at all — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). The core decision (shape every application-data node for multi-tenancy from day one) is unchanged and still correct.
- **Revisit if:** never — this remains intentionally permanent.

## ADR-009 — Pending decisions to record here once made

The following are intentionally **not yet decided**:

- Final choice of OCR provider/library — see [16_AI_MODULE.md](16_AI_MODULE.md).
- Final production font family — see [06_UI_UX_GUIDE.md § 3](06_UI_UX_GUIDE.md#3-typography).
- Where Gemini-generated insights are cached/stored in the schema — see [05_FEATURES.md § 12](05_FEATURES.md#12-analytics--ai-business-insights).
- Exact Surfboard API surface (endpoint paths, payload field names, auth scheme) once official integration docs/credentials are available — see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md). **Note:** this is narrower than it used to be — the *ownership model* (which entities Surfboard owns) is now confirmed (ADR-014); only the *wire-level specifics* remain open.
- **New in this pass:** real-time client strategy. Removing direct Flutter↔Firebase access (see [ADR-014](#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods) and [02_ARCHITECTURE.md § 2](02_ARCHITECTURE.md#2-frontend-flutter)) removes the real-time RTDB listener mechanism the original design leaned on for "instant" dashboard/sale-status updates. Whether the client now polls or the backend adds a push/streaming channel (WebSocket/SSE) is undecided — resolve before Phase 8 (Billing) or Phase 12 (Analytics) needs it (see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md)).
- ~~Backend validation library, logging library~~ — resolved, [ADR-010](#adr-010--backend-validation-library-zod)/[ADR-011](#adr-011--backend-logging-library-pino).
- ~~Lint/format tooling~~ — resolved, [ADR-012](#adr-012--lintformat-tooling-eslint-flat-config--prettier-not-airbnb-base).

## ADR-010 — Backend validation library: `zod`

- **Status:** Accepted — unaffected by this pass. See [21_BACKEND_GUIDELINES.md § 7](21_BACKEND_GUIDELINES.md#7-validator) for how this applies in the new layering.

## ADR-011 — Backend logging library: `pino`

- **Status:** Accepted — unaffected by this pass. See [21_BACKEND_GUIDELINES.md § 10](21_BACKEND_GUIDELINES.md#10-logging) for how this applies in the new layering, including Surfboard-call logging rules.

## ADR-012 — Lint/format tooling: ESLint flat config + Prettier (not Airbnb-base)

- **Status:** Accepted — unaffected by this pass.

## ADR-013 — `src/integrations/` vs `src/modules/` split

- **Status:** Accepted — **this pass builds directly on top of this decision** rather than changing it. Every Surfboard-owned domain now gets its own `modules/<domain>/` Domain Service calling into `integrations/surfboard/<domain>.client.js`, exactly matching the split this ADR established. See [ADR-016](#adr-016--surfboard-domain-module-split) for how it's applied to the seven Surfboard-owned entities specifically.

## ADR-014 — Surfboard is the system of record for Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods

- **Status:** Accepted
- **Context:** After researching the Surfboard Developer Portal and APIs, it became clear that Surfboard already models Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods as first-class objects with their own lifecycle, status, and identity. The original plan (a `merchants`/`stores`/`payments` Firebase schema that separately recorded a `surfboardMerchantId` reference field) would have meant **two systems tracking the same business object**, guaranteed to drift out of sync (a stale cached `status`, a Firebase record surviving after the Surfboard side changes, etc.) — exactly the "disconnected payments and POS" problem SurfPOS AI exists to solve (see [01_PROJECT_OVERVIEW.md § 3](01_PROJECT_OVERVIEW.md#3-business-problem)), just moved one layer down.
- **Decision:** Surfboard is the sole system of record for Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods. SurfPOS AI never persists a full copy of any of these in Firebase — it stores only the minimal ID reference needed to partition its own application data, and fetches everything else live through the Surfboard Integration Layer (see [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)).
- **Consequences:** Impossible for SurfPOS's copy of a Merchant/Store/Payment to drift from Surfboard's, because there is no copy. Every screen that needs this data makes a live call (through the Integration Layer, with short-lived in-process caching where appropriate — never RTDB persistence). Trade-off: the backend now has a hard runtime dependency on Surfboard's availability/latency for a much larger share of its functionality than "just payments" — see [02_ARCHITECTURE.md § 9](02_ARCHITECTURE.md#9-scalability) for the resulting caching/timeout/circuit-breaking requirement this creates.
- **Impact:** Removes `merchants/{merchantId}`, `stores/{storeId}`, `payments/{paymentId}` from [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) entirely; rewrites [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), [05_FEATURES.md](05_FEATURES.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md); amends [ADR-002](#adr-002--why-firebase-auth-realtime-database-storage-for-application-data)/[ADR-008](#adr-008--multi-tenant-data-model-from-day-one-multi-store-ui-deferred).
- **Revisit if:** Surfboard ever stops being the exclusive payments/merchant-identity integration (see [ADR-017](#adr-017--surfboard-payments-as-the-exclusive-payment-integration) for that separate, still-Accepted decision) — this ADR would need re-deriving from whatever replaces it.

## ADR-015 — Repository + Mapper pattern formalized

- **Status:** Accepted
- **Context:** [ADR-013](#adr-013--srcintegrations-vs-srcmodules-split) established that Firebase access and Surfboard access are separate layers, but didn't formalize the shape of the Firebase-access layer itself, or how wire-format translation happens on either side.
- **Decision:** Every Firebase-owned entity gets exactly one Repository (`<domain>.repository.js`) — the only code that calls the Firebase Admin SDK for that entity. Every Surfboard-owned entity's Integration Client is paired with a Mapper that translates Surfboard's wire format into the plain domain shapes defined in [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) (and Firebase records get a Mapper too, only where the raw shape needs translating). Full contract: [21_BACKEND_GUIDELINES.md §§ 4, 6](21_BACKEND_GUIDELINES.md#4-repository-firebase-owned-entities-only).
- **Consequences:** Services and Controllers never see a raw Firebase snapshot or raw Surfboard response body — only domain objects. A future Surfboard field-naming change is a one-file Mapper fix, not a hunt through every Service that touches that entity.
- **Revisit if:** never expected — this is a foundational code-organization decision, not a technology choice with an alternative to weigh.

## ADR-016 — Surfboard domain module split

- **Status:** Accepted
- **Context:** Earlier plans had one catch-all `modules/surfboard/` folder. With seven Surfboard-owned entities now formally distinguished ([ADR-014](#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)), a single module would violate the same single-responsibility principle every other domain module follows.
- **Decision:** `modules/merchant/`, `modules/store/`, `modules/device/`, `modules/payments/`, `modules/branding/` each own one or more of the seven entities. **Payment Methods folds into `modules/store/`** (it's queried/configured as a capability of a Store, not a standalone lifecycle) and **Tips folds into `modules/payments/`** (tips are configured and collected as part of the payment flow) — neither gets its own module or its own Integration Client file, to avoid a five-entities-worth-of-ceremony for two capabilities with no independent lifecycle of their own.
- **Consequences:** Five focused modules instead of one broad one; two capabilities (Payment Methods, Tips) live inside the module of the entity they're most tightly coupled to, rather than each getting a same-weight module despite having far less surface area. See [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md) for how each maps to its lifecycle, and [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) for how Payment Methods/Tips map onto the Phase 6/Phase 9 roadmap entries rather than getting their own phase number.
- **Revisit if:** Payment Methods or Tips ever grows an independent lifecycle (e.g. Surfboard exposes a standalone Tips API with its own onboarding/configuration flow unrelated to a single payment) — split it out into its own module/client at that point.

## ADR-017 — Surfboard Payments as the exclusive payment integration

- **Status:** Accepted
- **Context:** Surfboard Payments integration is a founding product requirement — SurfPOS AI is defined as "fully integrated with the Surfboard Payments ecosystem" (see [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md)). This decision was recorded as `D-009` in `.claude/decision.md` at project founding but never given a formal entry in this file — added here now for completeness during the Surfboard-alignment pass.
- **Decision:** Surfboard Payments is the exclusive payment-processing integration for SurfPOS AI — all payment intents, merchant/store/device onboarding, and settlement flow through Surfboard's API, called only from the backend's Integration Layer.
- **Consequences:** Single payment relationship for the merchant — directly solves the disconnected-payments business problem in [01_PROJECT_OVERVIEW.md § 3](01_PROJECT_OVERVIEW.md#3-business-problem). Trade-off: single point of dependency on one payment provider; exact API surface still pending confirmation (see [ADR-009](#adr-009--pending-decisions-to-record-here-once-made)).
- **Impact:** `backend/src/integrations/surfboard/`, `backend/src/modules/{merchant,store,device,payments,branding}/`, [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md), [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md).
- **Revisit if:** a second payment provider is ever required (e.g. geographic expansion beyond what Surfboard supports).

## ADR-018 — Surfboard SDK implementation choices (Phase 2)

- **Status:** Accepted
- **Context:** Building the real HTTP plumbing behind `src/integrations/surfboard/` (Roadmap Phase 2, see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md)) required several concrete technical choices not dictated by prior ADRs: which HTTP client library, what retry/backoff shape, and how to handle two specifics of the Surfboard wire format that are still unconfirmed (auth header scheme, webhook signature scheme).
- **Decision:**
  1. **Native `fetch`** (global in Node ≥ 18, this project's minimum) is used for all Surfboard HTTP calls — no `axios`/`got`/`node-fetch` dependency added, since the runtime already provides everything needed (streaming not required, `AbortSignal` timeout support built in).
  2. **Retry:** exponential backoff (`200ms × 2^attempt`), default 2 retries, only for retryable conditions — HTTP 408/429/500/502/503/504 or a network-level error (`AbortError`, `ECONNRESET`, `ETIMEDOUT`). A 4xx other than 408/429 is never retried, since retrying a client-error response can't fix it.
  3. **Timeout:** `AbortController`-based, default 10 seconds, configurable per client instance via dependency injection (see [21_BACKEND_GUIDELINES.md § 12](21_BACKEND_GUIDELINES.md#12-dependency-injection)).
  4. **Auth header scheme** (`middleware/auth.middleware.js`) and **webhook signature scheme** (`utils/webhookSignatureVerifier.js`, HMAC-SHA256 over the raw payload) are both **explicit placeholders** — a reasonable, common convention chosen so the SDK is fully testable end to end, but neither is verified against Surfboard's actual documentation yet (tracked under [ADR-009](#adr-009--pending-decisions-to-record-here-once-made)). Both are isolated in one file each specifically so confirming the real scheme later is a one-file change, not a rewrite. **Auth scheme superseded by [ADR-019](#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3)**, which replaces the single hardcoded placeholder with a pluggable strategy abstraction (`middleware/auth.middleware.js` retired in favor of `middleware/authentication.middleware.js`); the webhook signature scheme remains a placeholder, unaffected by that pass.
- **Consequences:** Zero new runtime dependencies for the SDK; every domain client gets working retry/timeout/logging/error-mapping for free by inheriting `client/surfboardClient.base.js`, with no domain-specific code duplicating any of it. Trade-off: the auth and webhook-signature placeholders will need updating (and their existing unit tests adjusting) once real Surfboard credentials/docs are available — this is expected, tracked work, not a currently-known bug.
- **Impact:** `backend/src/integrations/surfboard/{client,middleware,models,mappers,utils,errors}/`, `backend/tests/integrations/surfboard/` (48 tests), `backend/src/constants/{httpStatus,errorCodes,messages}.js` (added `BAD_GATEWAY`/`SURFBOARD_ERROR`).
- **Revisit if:** Surfboard's confirmed API documentation specifies a different auth scheme, signature scheme, or retry/rate-limit contract than assumed here — update the isolated file, not the SDK's overall shape.

## ADR-019 — Surfboard SDK authentication layer: strategy pattern (extends Phase 2, not Roadmap Phase 3)

- **Status:** Accepted
- **Context:** Phase 2 ([ADR-018](#adr-018--surfboard-sdk-implementation-choices-phase-2)) deliberately left `middleware/auth.middleware.js` as a single-scheme placeholder (a hardcoded Bearer-style header built from `apiKey`) because Surfboard's real auth mechanism is still unconfirmed against official docs ([ADR-009](#adr-009--pending-decisions-to-record-here-once-made)). This work completes that deferred placeholder. **Naming clarification:** this is *not* [Roadmap Phase 3 — Client Authentication](22_DEVELOPMENT_ROADMAP.md#phase-3--client-authentication), which is Firebase Auth (merchant/staff sign-in) and remains untouched, `Not Started`, and still gated on explicit user approval per [13_CLAUDE_CONTEXT.md § 5](13_CLAUDE_CONTEXT.md). This ADR is scoped entirely to how the backend authenticates *to* Surfboard's API, inside `src/integrations/surfboard/`.
- **Decision:** Replace the single hardcoded auth placeholder with a strategy-pattern abstraction so the auth scheme is swappable without touching `SurfboardBaseClient` or any domain client:
  - `auth/authStrategy.js` — the `AuthStrategy` contract (`getAuthHeaders()`) and `STRATEGY_TYPES` (`api_key`/`bearer`/`oauth`).
  - `auth/strategies/{apiKeyStrategy,bearerTokenStrategy,oauthStrategy}.js` — one concrete strategy per scheme. `ApiKeyStrategy` preserves Phase 2's exact default behavior (Bearer-style header built from the static API key) so nothing regresses while the real scheme is still unconfirmed. `BearerTokenStrategy`/`OAuthStrategy` are token-based and each own a `provider/tokenProvider.js` (cache + refresh-skew logic in `provider/tokenRefreshStrategy.js`, storage in `cache/tokenCache.js` with single-flight refresh dedup).
  - `auth/authenticationManager.js` — resolves `SURFBOARD_AUTH_STRATEGY` to a strategy instance via an injectable factory map (constructor-injection per [21_BACKEND_GUIDELINES.md § 12](21_BACKEND_GUIDELINES.md#12-dependency-injection)); `auth/authConfig.js` validates the chosen strategy has the credentials it needs, fail-fast; `auth/credentialLoader.js` is the one place credentials are read out of config, with a `redact()` helper so a secret never reaches a log line unmasked.
  - `middleware/authentication.middleware.js` (`attachAuthentication()`) replaces the retired `middleware/auth.middleware.js` as the request pipeline's auth step; `SurfboardBaseClient` now awaits it and holds an injected/default `AuthenticationManager`.
  - `OAuthStrategy` deliberately does **not** route its token-endpoint call through `SurfboardBaseClient` — the token endpoint must not be authenticated with the token it's about to issue, and doing so would create a circular dependency between the auth layer and the request layer.
- **Consequences:** Swapping `SURFBOARD_AUTH_STRATEGY=api_key|bearer|oauth` (or registering an entirely new strategy) requires no SDK code changes. Existing Phase 2 behavior/tests are preserved by default (`api_key` strategy, no env changes required). Trade-off: `OAuthStrategy`'s token endpoint path/grant/response shape are still placeholders pending Surfboard's real OAuth docs — isolated to one file, same pattern as [ADR-018](#adr-018--surfboard-sdk-implementation-choices-phase-2).
- **Impact:** `backend/src/integrations/surfboard/{auth,provider,cache}/`, `backend/src/integrations/surfboard/middleware/authentication.middleware.js` (new), `middleware/auth.middleware.js` (retired), `client/{surfboardClient.base,surfboardConfig}.js`, `src/config/index.js` + `src/constants/environmentKeys.js` (+`SURFBOARD_AUTH_STRATEGY`/`SURFBOARD_BEARER_TOKEN`), `backend/.env.example`. 27 new unit tests.
- **Revisit if:** Surfboard's confirmed docs specify a different scheme than any of the three strategies here (add a new strategy file + factory entry, per the pattern) or a different token-endpoint contract for `OAuthStrategy` (update that one file only).

---

**Next:** [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) — running log of prompts given to Claude and the resulting decisions.
