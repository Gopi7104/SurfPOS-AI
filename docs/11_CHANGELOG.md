# 11 — Changelog

> Format follows [Keep a Changelog](https://keepachangelog.com/) conventions and [Semantic Versioning](https://semver.org/). Related: [10_TASKS.md](10_TASKS.md) (what's planned), [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) (why each change was made). **Every merged change must add an entry under `[Unreleased]`**, moved into a version section at release time.

---

## [Unreleased]

### Added (Surfboard SDK Authentication Layer — extends Phase 2, not Roadmap Phase 3)
- A pluggable, strategy-pattern authentication layer for the Surfboard SDK under `backend/src/integrations/surfboard/{auth,provider,cache}/`, completing the Phase 2 auth-header placeholder ([ADR-018](08_ARCHITECTURE_DECISIONS.md#adr-018--surfboard-sdk-implementation-choices-phase-2)) now that it has real strategy support instead of one hardcoded scheme: `auth/authStrategy.js` (contract + `STRATEGY_TYPES`), `auth/strategies/{apiKeyStrategy,bearerTokenStrategy,oauthStrategy}.js`, `auth/authenticationManager.js` (strategy selection/orchestration), `auth/authConfig.js` (fail-fast credential validation per strategy), `auth/credentialLoader.js` (secure credential loading + redaction), `provider/tokenProvider.js` + `provider/tokenRefreshStrategy.js` (cached, auto-refreshing tokens for the bearer/oauth strategies), `cache/tokenCache.js` (TTL cache with single-flight refresh dedup).
- `middleware/authentication.middleware.js` (`attachAuthentication()`) replaces the retired Phase 2 placeholder `middleware/auth.middleware.js` as the request pipeline's auth step; `client/surfboardClient.base.js` now awaits it via an injected/default `AuthenticationManager` — default behavior (`api_key` strategy) is unchanged from Phase 2.
- `SURFBOARD_AUTH_STRATEGY` (`api_key`|`bearer`|`oauth`, default `api_key`) and `SURFBOARD_BEARER_TOKEN` added to `backend/src/config/index.js`, `backend/src/constants/environmentKeys.js`, and `backend/.env.example`.
- 27 new unit tests in `backend/tests/integrations/surfboard/` (token cache, refresh strategy, token provider, credential loader, auth config validation, all three strategies, authentication manager, authentication middleware) plus 2 new `surfboardClient.base.test.js` cases covering strategy injection — all against mocked HTTP/fake credentials, no real Surfboard calls. Total Surfboard SDK suite: 97 tests.
- ADR-019 in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3): the strategy-pattern decision, and an explicit naming clarification that this is distinct from [Roadmap Phase 3 — Client Authentication](22_DEVELOPMENT_ROADMAP.md#phase-3--client-authentication) (Firebase merchant/staff sign-in), which remains untouched and still gated on approval.

### Added (Phase 2 — Surfboard Client SDK)
- Real Surfboard SDK infrastructure under `backend/src/integrations/surfboard/`: `client/` (base HTTP client + environment-aware config, sandbox/production switching), `middleware/` (retry with exponential backoff, `AbortController` timeout, auth-header placeholder, request/response logging), `models/` (JSDoc-only request/response/environment shapes), `mappers/` (`BaseMapper` contract for future domain mappers), `utils/` (request ID generation, request builder, response parser, webhook HMAC signature verifier), `errors/` (`SurfboardApiError`, a normalizing error mapper).
- Every domain client (`auth`, `merchant`, `payment`, `store`, `device`, `branding`) now inherits a fully working `request()` — auth headers, retry, timeout, request IDs, and logging happen automatically. **No domain method was added to any client** (no `createMerchant()`, etc.) — still deferred to each entity's owning phase.
- 48 unit tests in `backend/tests/integrations/surfboard/` covering the base client, retry, timeout, request builder, response parser, error mapper, webhook signature verifier, auth placeholder, request ID generation, and the base mapper contract — all against a mocked HTTP layer, no real network calls.
- `HTTP_STATUS.BAD_GATEWAY` (502) and `ERROR_CODES.SURFBOARD_ERROR` added to `backend/src/constants/`.
- ADR-018 in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md): SDK implementation choices (native `fetch`, retry/timeout defaults, and the two explicit placeholders — auth scheme, webhook signature scheme — pending real Surfboard docs).

### Added (Surfboard-alignment documentation pass)
- Four new documentation files: [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md) (Merchant/Store/Device/Payment lifecycles, Branding/Tips/Payment Methods workflows), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) (core entity definitions and the Surfboard-vs-Firebase ownership rule), [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) (Controller/Service/Repository/Integration/Mapper/Validator layering, error handling, logging, testing, DI, folder ownership), [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) (new 13-phase implementation order).
- A `Supplier` entity (`suppliers/{merchantId}/{supplierId}`), replacing the previous free-text `supplierName` field on `orders`/`invoiceScans`.
- ADR-014 through ADR-017 in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md): Surfboard as system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods; Repository + Mapper pattern formalized; the Surfboard domain module split (`modules/merchant/`, `modules/store/`, `modules/device/`, `modules/payments/`, `modules/branding/`); and a proper ADR for the founding Surfboard-exclusivity decision.
- A new `SURFBOARD_ERROR` standard error code / `502` status in [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), for upstream Surfboard API failures specifically.

### Changed (Surfboard-alignment documentation pass)
- Full rewrite of [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md), [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), [05_FEATURES.md](05_FEATURES.md), [07_CODING_RULES.md](07_CODING_RULES.md), [10_TASKS.md](10_TASKS.md), [12_README.md](12_README.md), [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md), and [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) to reflect Surfboard-as-system-of-record — the Flutter app now talks only to the backend (no direct Firebase/Surfboard client access); Firebase holds application data only.
- Lighter-touch updates to [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md), [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md), [16_AI_MODULE.md](16_AI_MODULE.md), [18_CONTRIBUTING.md](18_CONTRIBUTING.md).
- ADR-002 and ADR-008 amended in place (status/context clarified, original text preserved) rather than deleted, per [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)'s own "never edit history away" rule.

### Removed (Surfboard-alignment documentation pass)
- `merchants/{merchantId}`, `stores/{storeId}`, and `payments/{paymentId}` as Firebase Realtime Database nodes — these entities are now fetched live from Surfboard and never persisted in Firebase (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). No code implemented these nodes yet, so this is a documentation-only removal with no migration required.
- Direct Flutter↔Firebase and Flutter↔Surfboard client access from the architecture — the Flutter app now talks only to the backend.

### Added
- Complete project documentation system in `/docs` (18 files): project overview, architecture, database design, API reference, feature specs, UI/UX guide, coding rules, architecture decisions, prompt history, task roadmap, README, Claude context file, developer guide, Surfboard integration guide, AI module guide, folder structure, and contributing guide.
- Complete enterprise repository folder structure: `frontend/` (Flutter, feature-first), `backend/` (Node/Express, layered + module-based), `firebase/` (Security Rules config), `scripts/`, `api-testing/`, `design/`, `.github/` (workflows, issue/PR templates), `.vscode/`, plus root `.gitignore`, `LICENSE` (placeholder — unchosen), `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `package.json`. Every folder currently holds only placeholder READMEs/`.gitkeep`/stub entry-point files — no functionality implemented.
- Backend foundational scaffolding (real code, no longer placeholders): `backend/src/config` (env loading/validation via `zod`, fail-fast in production), `backend/src/utils/logger.js` (`pino`, per-request child loggers), `backend/src/utils/errors.js` (typed `AppError` hierarchy matching the documented error codes), `backend/src/utils/response.js` (standard success/error envelope), `backend/src/utils/asyncHandler.js`, `backend/src/firebase/admin.js` (lazy Firebase Admin SDK init — safe to boot without credentials), `backend/src/middleware/{auth,validate,error}.middleware.js`, `backend/src/{routes,controllers,services}/health.*`, `backend/src/app.js` + `backend/src/server.js`. Verified booting locally and `GET /health` responding with the standard envelope.
- `GET /health` endpoint — public liveness probe, documented in [04_API_DOCUMENTATION.md § 13](04_API_DOCUMENTATION.md#13-health--infra).
- ADR-010 (`zod` for backend validation) and ADR-011 (`pino` for backend logging) in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md), resolving two of the five items in ADR-009.
- Backend infrastructure hardening (task 0.8): ESLint flat config + Prettier (`backend/eslint.config.js`, `.prettierrc.json`) with `lint`/`lint:fix`/`format`/`format:check` scripts; Husky pre-commit hook (repo-root `.husky/pre-commit`) running backend lint, format-check, and tests; `compression` and a global `express-rate-limit` limiter (bypassing `GET /health`); a full `backend/src/constants/` layer (HTTP status, error codes, messages, roles, permissions, API routes/version, regex, env keys) that `utils/errors.js`, `utils/response.js`, `middleware/error.middleware.js`, `middleware/auth.middleware.js`, `config/index.js`, and `app.js` now consume instead of inline literals; `backend/src/types/` JSDoc-only shared type definitions; `backend/src/integrations/surfboard/` placeholder client architecture (`auth`/`merchant`/`payment`/`store`/`device`/`branding.client.js` — no real API calls yet); richer per-request logging (requestId, method, url, status, response time, IP, user agent, merchant/user ID when available); a Vitest + Supertest test suite (`GET /health`, 404 handler, response envelope helpers — 7 tests); a `backend/src/docs/swagger/` folder skeleton (`paths/`, `components/`, `schemas/`, no spec generated yet); `.github/workflows/backend.yml` CI pipeline (install/lint/format-check/test/build).
- ADR-012 (ESLint flat config instead of Airbnb-base) and ADR-013 (`src/integrations/` vs `src/modules/` split) in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).

### Changed
- Renamed the planned frontend folder from `mobile/` to `frontend/` across the documentation set to match the actual scaffolded structure (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).

### Removed
- N/A

### Fixed
- N/A

---

## [0.1.0] — Unreleased (Documentation Baseline)

_This version tag is reserved for "documentation complete, no application code yet." It will be superseded by `0.2.0` at the end of Phase 1 (see [10_TASKS.md](10_TASKS.md))._

### Added
- Initial `/docs` knowledge base (see `[Unreleased]` above for full contents).

---

**Next:** [12_README.md](12_README.md) — the public-facing project README.
