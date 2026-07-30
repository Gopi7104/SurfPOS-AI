
# Decision Log

> Read after [project.md](project.md) and [projectStatus.md](projectStatus.md), before [memory.md](memory.md). See [project.md § Read these files next](project.md#read-these-files-next) for the full session-start reading order.

---

## Purpose

This file is the permanent record of **why** SurfPOS AI is built the way it is. Every architectural or technical decision of consequence — a technology choice, a market/business-model choice, a design-philosophy choice — is recorded here with its reasoning, alternatives, and trade-offs, so that:

- A future Claude session (or human developer) never has to guess *why* something was built a certain way, or accidentally re-litigate a settled decision without knowing it was already considered.
- A decision that turns out to be wrong can be revisited with full context on what was known at the time, rather than from scratch.
- Decisions stay attributable and dated, instead of being buried in chat history or commit messages.

This file is the `.claude/`-local counterpart to [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md) — where the two overlap, this file cross-references the matching ADR number there rather than duplicating its full text. **This file is for Claude's fast working reference; `docs/08_ARCHITECTURE_DECISIONS.md` remains the long-form, human-facing ADR document.** When a decision is added or changed here, add or update the corresponding ADR there too.

**Do not store working notes, open questions, or unconfirmed ideas here** — those belong in [memory.md](memory.md). Only decisions that have actually been made belong in this file.

---

## Decision Template

Copy this block for every new decision:

```
### D-0XX — <short title>

- **Decision Number:** D-0XX
- **Date:** YYYY-MM-DD
- **Decision:** What was decided, stated plainly.
- **Reason:** Why this was chosen — the driving requirement or constraint.
- **Alternatives Considered:** What else was on the table, and why it lost.
- **Pros:** What this choice gives us.
- **Cons:** What this choice costs us / what it makes harder.
- **Impact:** What this touches — schema, docs, folders, other decisions.
- **Status:** Proposed | Accepted | Superseded by D-0YY
- **Owner:** Who made / owns this decision.
```

---

## Decision Log

### D-001 — Flutter chosen for frontend

- **Decision Number:** D-001
- **Date:** 2026-07-29
- **Decision:** Flutter (Dart) is the single frontend codebase for Android and iOS.
- **Reason:** SurfPOS AI must ship on both major mobile platforms, mobile-first, with a UI-heavy feature set (camera/barcode scanning, real-time listeners) and a small engineering team — one codebase instead of two native ones.
- **Alternatives Considered:** Separate native apps (Kotlin/Swift); React Native.
- **Pros:** One codebase for both platforms; strong first-party Firebase SDK support; mature camera/barcode plugin ecosystem.
- **Cons:** Smaller hiring pool than native or React Native/TypeScript; deep native-only capability requires a platform channel.
- **Impact:** Defines the entire `frontend/` folder structure (see [docs/17_FOLDER_STRUCTURE.md § 2](../docs/17_FOLDER_STRUCTURE.md#2-frontend-flutter--full-tree)).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-001](../docs/08_ARCHITECTURE_DECISIONS.md#adr-001--why-flutter-for-the-frontend)

### D-002 — Node.js + Express chosen for backend

- **Decision Number:** D-002
- **Date:** 2026-07-29
- **Decision:** Node.js + Express.js as a thin, stateless REST API layer.
- **Reason:** The backend's job is orchestration (Firebase Admin SDK, Gemini API, OCR, Surfboard Payments) — I/O-bound, not CPU-bound — which suits Node's async model well.
- **Alternatives Considered:** Python (FastAPI/Django); Go; Java/Spring.
- **Pros:** Naturally async, well suited to orchestrating multiple external calls per request; huge ecosystem for HTTP clients/SDKs.
- **Cons:** Not ideal for CPU-heavy work (e.g. in-process image processing), which would need to be isolated if ever required.
- **Impact:** Defines `backend/src/` layered structure (see [docs/17_FOLDER_STRUCTURE.md § 3](../docs/17_FOLDER_STRUCTURE.md#3-backend-nodejs--express--full-tree)).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-003](../docs/08_ARCHITECTURE_DECISIONS.md#adr-003--why-nodejs--express-for-the-backend)

### D-003 — Firebase Realtime Database selected

- **Decision Number:** D-003
- **Date:** 2026-07-29
- **Decision:** Firebase Realtime Database is the single source of truth for all application data — no separate SQL/NoSQL datastore.
- **Reason:** Target customers cannot manage servers, backups, or database administration; real-time UI updates (live inventory, live sale status) are core to the product feel.
- **Alternatives Considered:** Firestore; a managed SQL database (Postgres/MySQL) behind the backend.
- **Pros:** Zero database-ops burden; real-time sync to the client built in; tight integration with Firebase Auth Security Rules.
- **Cons:** No relational/complex queries — every access pattern must be designed into the tree shape and denormalized up front; practical per-instance scaling ceilings.
- **Impact:** Defines the entire schema in [docs/03_DATABASE_DESIGN.md](../docs/03_DATABASE_DESIGN.md).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-002](../docs/08_ARCHITECTURE_DECISIONS.md#adr-002--why-firebase-auth-realtime-database-storage-over-a-custom-backend-datastore)

### D-004 — Firebase Authentication selected

- **Decision Number:** D-004
- **Date:** 2026-07-29
- **Decision:** Firebase Authentication (email/password + phone OTP) is the identity provider for owners and staff.
- **Reason:** Native integration with Firebase RTDB Security Rules and the Admin SDK token-verification flow used by the backend; avoids building/maintaining a custom auth system.
- **Alternatives Considered:** Auth0; a custom JWT-based auth system.
- **Pros:** Verified ID tokens are trivially checked server-side via Firebase Admin SDK; no password storage/liability for SurfPOS AI.
- **Cons:** Coupled to the Firebase ecosystem — migrating identity providers later would touch both client and backend auth code.
- **Impact:** `auth.middleware.js` (backend), `features/authentication/` (frontend) — see [docs/05_FEATURES.md § 2](../docs/05_FEATURES.md#2-authentication).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-002](../docs/08_ARCHITECTURE_DECISIONS.md#adr-002--why-firebase-auth-realtime-database-storage-over-a-custom-backend-datastore)

### D-005 — Firebase Storage selected

- **Decision Number:** D-005
- **Date:** 2026-07-29
- **Decision:** Firebase Storage holds all binary assets — product images, invoice scan photos, generated receipt PDFs.
- **Reason:** Same operational-simplicity rationale as D-003/D-004 — no separate object-storage/CDN service to provision, secure, or bill separately; integrates with the same Firebase Security Rules model.
- **Alternatives Considered:** AWS S3 / Google Cloud Storage directly.
- **Pros:** One platform for the entire data layer (DB + Auth + Storage); consistent security-rule model.
- **Cons:** Tied to Firebase's storage pricing/limits rather than a general-purpose object store.
- **Impact:** `invoiceScans/{scanId}.imageUrl`, `receipts/{receiptId}.pdfUrl`, product `imageUrl` fields — see [docs/03_DATABASE_DESIGN.md](../docs/03_DATABASE_DESIGN.md).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-002](../docs/08_ARCHITECTURE_DECISIONS.md#adr-002--why-firebase-auth-realtime-database-storage-over-a-custom-backend-datastore)

### D-006 — Smartphone-first POS architecture

- **Decision Number:** D-006
- **Date:** 2026-07-29
- **Decision:** No dedicated POS terminal or external barcode scanner is required — the merchant's own phone camera is the barcode/invoice scanner, and payment acceptance uses whatever Surfboard-supported method works from the phone.
- **Reason:** Dedicated POS hardware is a major upfront cost barrier for the target small-retailer customer.
- **Alternatives Considered:** Requiring a dedicated POS terminal/tablet + external barcode scanner (the traditional retail-hardware model).
- **Pros:** Zero-hardware onboarding; lowest possible total cost of ownership for the merchant.
- **Cons:** Reliant on phone camera barcode-read reliability; may still require a small Surfboard-provided reader depending on which payment rails Surfboard requires for card-present transactions (to confirm — see [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md)).
- **Impact:** Drives the `barcode/` and `invoice_ai/` feature designs — see [docs/05_FEATURES.md §§ 5–6](../docs/05_FEATURES.md#5-barcode-scanner).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-005](../docs/08_ARCHITECTURE_DECISIONS.md#adr-005--why-smartphone-only-pos-no-dedicated-terminalhardware-requirement)

### D-007 — AI invoice OCR approach

- **Decision Number:** D-007
- **Date:** 2026-07-29
- **Decision:** Supplier invoices are photographed, OCR'd to raw text, structured into line items by an AI model, then **always reviewed and confirmed by the merchant** before anything is written to inventory or purchase orders. Full automation without human review is explicitly out of scope for now.
- **Reason:** Manual invoice re-entry is the single biggest identified time cost for the target customer; OCR/AI accuracy varies with photo quality and invoice format, so an unreviewed auto-commit would risk silently corrupting inventory/cost data.
- **Alternatives Considered:** Manual entry only (status quo); fully automated extraction with no review step.
- **Pros:** Removes manual re-typing for the common case while keeping a human check on anything that affects money/stock.
- **Cons:** Requires a review UI and adds a step before stock updates land (not instantaneous).
- **Impact:** `invoiceScans/{scanId}` schema, `invoice_ai/` frontend feature, `modules/ai/` backend module — see [docs/16_AI_MODULE.md](../docs/16_AI_MODULE.md).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-004](../docs/08_ARCHITECTURE_DECISIONS.md#adr-004--why-ai-ocr--gemini-for-invoice-scanning-vs-manual-entry-only)

### D-008 — Gemini AI selected

- **Decision Number:** D-008
- **Date:** 2026-07-29
- **Decision:** Gemini API is the AI reasoning engine used to (a) structure raw OCR text into line items and match them to the product catalog, and (b) generate plain-language business insights from aggregated sales data.
- **Reason:** Needed a capable general-purpose LLM for both structured-extraction and natural-language-generation tasks behind a single API, orchestrated entirely server-side.
- **Alternatives Considered:** OpenAI GPT models; a smaller task-specific/open-source model self-hosted by the backend.
- **Pros:** One provider/API surface for both AI responsibilities; strong structured-output capability for the extraction task.
- **Cons:** External dependency and per-call cost; output must always be validated before being trusted (see [docs/16_AI_MODULE.md § 3](../docs/16_AI_MODULE.md#3-gemini-prompting)).
- **Impact:** `backend/src/modules/ai/` (Gemini service, prompt templates) — see [docs/16_AI_MODULE.md](../docs/16_AI_MODULE.md).
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-004](../docs/08_ARCHITECTURE_DECISIONS.md#adr-004--why-ai-ocr--gemini-for-invoice-scanning-vs-manual-entry-only) (Gemini is named there as part of the OCR pipeline decision; this entry isolates the model/provider choice specifically)

### D-009 — Surfboard Payments integration

- **Decision Number:** D-009
- **Date:** 2026-07-29
- **Decision:** Surfboard Payments is the exclusive payment-processing integration for SurfPOS AI — all payment intents, merchant onboarding, and settlement flow through Surfboard's API, called only from the backend.
- **Reason:** Surfboard Payments integration is a founding product requirement, not an incidental technology choice — SurfPOS AI is defined as "fully integrated with the Surfboard Payments ecosystem."
- **Alternatives Considered:** Stripe; a locally-relevant payment gateway; supporting multiple payment processors from day one.
- **Pros:** Single payment relationship for the merchant (no separate POS + payments vendor split — directly solves the disconnected-payments business problem in [docs/01_PROJECT_OVERVIEW.md § 3](../docs/01_PROJECT_OVERVIEW.md#3-business-problem)).
- **Cons:** Single point of dependency on one payment provider; exact API surface not yet confirmed against official Surfboard documentation (see [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md) accuracy note).
- **Impact (as originally recorded — see amendment below):** ~~`backend/src/modules/surfboard/`, `payments/{paymentId}` schema~~, `POST /webhooks/surfboard` — see [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md).
- **Amendment (2026-07-29, Surfboard-alignment pass):** The original Impact line assumed a `payments/{paymentId}` Firebase schema and a single catch-all `modules/surfboard/` folder. Neither exists anymore: Surfboard payment data is never persisted in Firebase (see [D-016](#d-016--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)), and `modules/surfboard/` was split into `modules/{merchant,store,device,payments,branding}/` (see [D-018](#d-018--surfboard-domain-module-split-tipspayment-methods-folded-in-not-standalone)). The core decision this entry records — Surfboard as the exclusive payment integration — is unchanged and still fully accurate; now formalized as a proper ADR (it previously had none, see the note below).
- **Status:** Accepted (integration pattern defined; exact wire-level API surface pending confirmation against official docs)
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md), now formalized as [docs/08_ARCHITECTURE_DECISIONS.md § ADR-017](../docs/08_ARCHITECTURE_DECISIONS.md#adr-017--surfboard-payments-as-the-exclusive-payment-integration) (added during the Surfboard-alignment pass — this entry previously had no formal ADR).

### D-010 — Sweden (SEK) selected instead of INR

- **Decision Number:** D-010
- **Date:** 2026-07-29
- **Decision:** The target market/currency for SurfPOS AI is **Sweden**, using **SEK (Swedish Krona)** — not India/INR as earlier examples in `/docs` assumed.
- **Reason:** Business-direction decision by the project owner to target the Swedish small-retail market.
- **Alternatives Considered:** Continuing with the original India/INR-oriented framing; designing for multi-currency/multi-market from day one.
- **Pros:** Clear, single-market focus for Phase 1 (avoids the complexity of a multi-currency/multi-tax-regime build before there's a validated product).
- **Cons:** **This decision was made after several `/docs` files were already written with India-specific examples and is not yet propagated.** Concretely still stale as of this writing:
  - [docs/03_DATABASE_DESIGN.md](../docs/03_DATABASE_DESIGN.md) — `currency: "INR"` example values, `gstNumber` field (India-specific; Sweden uses an *organisationsnummer* and *moms*/VAT, not GST), `timezone: "Asia/Kolkata"` example.
  - [docs/01_PROJECT_OVERVIEW.md](../docs/01_PROJECT_OVERVIEW.md) — implicit India framing in business-problem examples.
  - [docs/05_FEATURES.md](../docs/05_FEATURES.md) / [docs/13_CLAUDE_CONTEXT.md](../docs/13_CLAUDE_CONTEXT.md) — any India-specific phrasing carried through from the original examples.
  - Tax terminology throughout should move from "GST" to Sweden's **moms** (VAT) model.
- **Impact:** Schema field rename/redefinition (`gstNumber` → an org-number equivalent), default currency/timezone/locale changes, tax-settings defaults, and address-format assumptions. **This is a data-model and documentation change, not yet made — see [projectStatus.md § Known Issues](projectStatus.md#known-issues) and [projectStatus.md § Next Tasks](projectStatus.md#next-tasks).**
- **Status:** Accepted — market/currency decision is final; propagation into `/docs` and the (not-yet-written) schema/code is **pending**.
- **Owner:** Velan (project owner)
- **Cross-reference:** Not yet reflected in [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md) — add as a new ADR (next available slot: ADR-010 or ADR-011, depending on ordering with D-009) when the propagation work is scheduled.

### D-011 — Mobile-first design philosophy

- **Decision Number:** D-011
- **Date:** 2026-07-29
- **Decision:** Every UI/UX decision optimizes for one-handed use at a counter, in a hurry, in variable lighting — speed and legibility over decoration.
- **Reason:** The primary user of the billing/checkout flow is a cashier mid-transaction, often interrupted, not a desk user browsing at leisure.
- **Alternatives Considered:** A conventional "desktop-POS-shrunk-to-mobile" design approach; tablet-first design with phone as a secondary target.
- **Pros:** Directly shapes concrete, testable UI rules (thumb-reachable primary actions, high-contrast color use, purposeful-only animation) rather than leaving "mobile-first" as an unenforceable slogan.
- **Cons:** Tablet/desktop-optimized layouts are explicitly deferred (see [docs/06_UI_UX_GUIDE.md § 10](../docs/06_UI_UX_GUIDE.md#10-responsive-rules)), so those experiences will need dedicated design work later rather than falling out "for free."
- **Impact:** The entire [docs/06_UI_UX_GUIDE.md](../docs/06_UI_UX_GUIDE.md) design system is derived from this decision.
- **Status:** Accepted
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/06_UI_UX_GUIDE.md § 1](../docs/06_UI_UX_GUIDE.md#1-design-philosophy) (this is a design-philosophy decision distinct from [D-006](#d-006--smartphone-first-pos-architecture), which is about hardware, not UI design)

### D-012 — Backend validation library: `zod`

- **Decision Number:** D-012
- **Date:** 2026-07-29
- **Decision:** Use `zod` for all backend request-schema validation (`validate.middleware.js` + one schema per resource under `backend/src/validators/`).
- **Reason:** Blocked Phase 1 backend scaffolding per `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`; needed before `validate.middleware.js` could be written. Confirmed with the project owner via direct question rather than picked silently.
- **Alternatives Considered:** `Joi`.
- **Pros:** Fluent schema composition; schemas double as a single source of truth for request shape.
- **Cons:** No compile-time type-inference benefit since the backend is plain JS, not TypeScript.
- **Impact:** `backend/src/middleware/validate.middleware.js`, every `backend/src/validators/*.js` file going forward.
- **Status:** Accepted
- **Owner:** Gopi (confirmed via direct question during Phase 1 backend foundation work)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-010](../docs/08_ARCHITECTURE_DECISIONS.md#adr-010--backend-validation-library-zod)

### D-013 — Backend logging library: `pino`

- **Decision Number:** D-013
- **Date:** 2026-07-29
- **Decision:** Use `pino` (+ `pino-http`) as the single backend logger instance.
- **Reason:** Blocked Phase 1 backend scaffolding per `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`; needed before `utils/logger.js` could be written. Confirmed with the project owner via direct question rather than picked silently.
- **Alternatives Considered:** `winston`.
- **Pros:** Low overhead, fast structured JSON logging, cheap child loggers for per-request `requestId`/`merchantId` context.
- **Cons:** Fewer built-in transports than `winston` — multi-destination shipping would rely on `pino` transport plugins.
- **Impact:** `backend/src/utils/logger.js`, `pino-http` wiring in `backend/src/app.js`.
- **Status:** Accepted
- **Owner:** Gopi (confirmed via direct question during Phase 1 backend foundation work)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-011](../docs/08_ARCHITECTURE_DECISIONS.md#adr-011--backend-logging-library-pino)

### D-014 — Lint/format tooling: ESLint flat config + Prettier (not Airbnb-base)

- **Decision Number:** D-014
- **Date:** 2026-07-29
- **Decision:** ESLint flat config (`@eslint/js` recommended + a small custom ruleset matching `docs/07_CODING_RULES.md`) plus `eslint-config-prettier`, rather than `eslint-config-airbnb-base`.
- **Reason:** `07_CODING_RULES.md § 1` left the exact lint stack open ("Airbnb-base or equivalent"); ESLint's flat-config default and Airbnb-base's heavier/still-transitioning flat-config support made a lean custom ruleset the more maintainable choice for this project's actual documented conventions.
- **Alternatives Considered:** `eslint-config-airbnb-base` (with `@eslint/eslintrc`'s `FlatCompat` shim).
- **Pros:** Every rule maps directly to something `docs/07_CODING_RULES.md` already says; no legacy-config compatibility layer.
- **Cons:** Doesn't inherit Airbnb's broad "gotcha" rule coverage — new rules get added deliberately as needed, not for free.
- **Impact:** `backend/eslint.config.js`, `backend/.prettierrc.json`.
- **Status:** Accepted
- **Owner:** Gopi (backend infrastructure hardening pass)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-012](../docs/08_ARCHITECTURE_DECISIONS.md#adr-012--lintformat-tooling-eslint-flat-config--prettier-not-airbnb-base)

### D-015 — `src/integrations/` vs `src/modules/` split

- **Decision Number:** D-015
- **Date:** 2026-07-29
- **Decision:** `backend/src/integrations/<provider>/` holds raw, reusable third-party HTTP client wrappers (no business logic); `backend/src/modules/<provider>/` holds the business/orchestration logic that calls into those clients.
- **Reason:** A task asked for Surfboard placeholder clients under a new `src/integrations/surfboard/` folder, which would otherwise duplicate the already-reserved `src/modules/surfboard/` from `docs/17_FOLDER_STRUCTURE.md`. Splitting by responsibility (client plumbing vs. business rules) resolves the overlap instead of picking one arbitrarily.
- **Alternatives Considered:** Putting everything in `modules/surfboard/` (mixing client + business logic); renaming `modules/surfboard/` away entirely.
- **Pros:** Client layer stays swappable/mockable independent of business rules — directly supports "use interfaces so Surfboard APIs can be mocked during development" from the project's stated implementation strategy.
- **Cons:** One more top-level folder to explain to a new contributor.
- **Impact:** `backend/src/integrations/surfboard/*`, `docs/17_FOLDER_STRUCTURE.md`, `backend/src/modules/surfboard/README.md`.
- **Status:** Accepted
- **Owner:** Gopi (backend infrastructure hardening pass)
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-013](../docs/08_ARCHITECTURE_DECISIONS.md#adr-013--srcintegrations-vs-srcmodules-split)

### D-016 — Surfboard is the system of record for Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods

- **Decision Number:** D-016
- **Date:** 2026-07-29
- **Decision:** Surfboard owns Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods outright — SurfPOS AI never persists a full copy of any of these in Firebase, only the minimal ID reference needed to partition its own application data.
- **Reason:** After researching the Surfboard Developer Portal, it became clear Surfboard already models these as first-class objects with their own lifecycle/status/identity. The original plan (a parallel `merchants`/`stores`/`payments` Firebase schema referencing Surfboard by ID) would have created two systems tracking the same business object — the exact "disconnected payments and POS" problem SurfPOS exists to solve, recreated one layer down.
- **Alternatives Considered:** Keep a cached Firebase copy synced via webhooks (rejected — sync drift risk, exactly what this decision avoids); keep the original plan as-is until it caused a visible bug (rejected — no code implements it yet, so correcting now is free).
- **Pros:** Impossible for SurfPOS's copy to drift from Surfboard's truth, because there is no copy.
- **Cons:** The backend now has a hard runtime dependency on Surfboard's availability/latency for a much larger share of functionality — requires caching/timeout/circuit-breaking discipline at the Integration Client layer.
- **Impact:** Full rewrite of `docs/01–05, 07, 08, 10, 12, 13, 15, 17`; four new docs (`docs/19–22`); no code impact (Phase 1 never implemented merchant/store/payment persistence).
- **Status:** Accepted
- **Owner:** Velan (Lead Architect direction), implemented by Claude
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-014](../docs/08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods), [docs/20_DOMAIN_MODEL.md § 1](../docs/20_DOMAIN_MODEL.md#1-the-ownership-principle)

### D-017 — Repository + Mapper pattern formalized

- **Decision Number:** D-017
- **Date:** 2026-07-29
- **Decision:** Every Firebase-owned entity gets exactly one Repository; every Surfboard Integration Client is paired with a Mapper translating wire format to the domain shapes in `docs/20_DOMAIN_MODEL.md`.
- **Reason:** [D-015](#d-015--srcintegrations-vs-srcmodules-split) established the integrations/modules split but not the shape of the Firebase-access layer itself or how wire-format translation happens — needed once Surfboard became the source of record for seven distinct entities (D-016).
- **Pros:** Services/Controllers never see a raw Firebase snapshot or raw Surfboard response — only domain objects; a Surfboard field-naming change is a one-file Mapper fix.
- **Cons:** More files per domain (service + repository/mapper) than a flatter structure would have.
- **Impact:** `backend/src/modules/<domain>/{<domain>.repository.js, <domain>.mapper.js}`, `backend/src/integrations/surfboard/mappers/`.
- **Status:** Accepted
- **Owner:** Velan (Lead Architect direction), implemented by Claude
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-015](../docs/08_ARCHITECTURE_DECISIONS.md#adr-015--repository--mapper-pattern-formalized), [docs/21_BACKEND_GUIDELINES.md](../docs/21_BACKEND_GUIDELINES.md)

### D-018 — Surfboard domain module split (Tips/Payment Methods folded in, not standalone)

- **Decision Number:** D-018
- **Date:** 2026-07-29
- **Decision:** One backend module per Surfboard-owned entity (`merchant/`, `store/`, `device/`, `payments/`, `branding/`), replacing the old single catch-all `modules/surfboard/`. Payment Methods folds into `store/`; Tips folds into `payments/` — neither gets its own module or Integration Client file.
- **Reason:** A single `modules/surfboard/` would violate the single-responsibility principle every other domain module follows now that seven distinct entities are formally recognized (D-016). Payment Methods/Tips have no independent lifecycle of their own — full modules for them would be ceremony without benefit.
- **Pros:** Five focused modules instead of one broad one; Payment Methods/Tips live next to the entity they're most tightly coupled to.
- **Cons:** If Surfboard later exposes Payment Methods/Tips as fully independent APIs with their own lifecycle, they'd need to be split out.
- **Impact:** `backend/src/modules/{merchant,store,device,payments,branding}/`, `docs/17_FOLDER_STRUCTURE.md`.
- **Status:** Accepted
- **Owner:** Velan (Lead Architect direction), implemented by Claude
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-016](../docs/08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split)

### D-019 — Surfboard SDK implementation choices: native `fetch`, retry/timeout defaults, placeholder auth + webhook schemes

- **Decision Number:** D-019
- **Date:** 2026-07-29
- **Decision:** The Surfboard SDK (Roadmap Phase 2) uses native `fetch` (no new HTTP dependency), exponential-backoff retry (200ms × 2^attempt, 2 retries, retryable-status-aware: 408/429/5xx or network error), `AbortController` timeout (10s default) — and ships two **explicit, isolated placeholders**: a Bearer-token auth header scheme and an HMAC-SHA256 webhook signature scheme, both pending confirmation against real Surfboard docs.
- **Reason:** Building the SDK's shape and testing it end-to-end didn't require real Surfboard credentials or docs — a reasonable, common-convention placeholder for the two genuinely-unconfirmed pieces (auth, webhook signing) let the whole request pipeline (retry/timeout/logging/error-mapping) be built and fully unit-tested now, isolated so confirming the real scheme later is a one-file change each.
- **Alternatives Considered:** Adding `axios`/`got` as a dependency (rejected — native `fetch` already covers everything needed); waiting for real Surfboard credentials before writing any SDK code (rejected — would have blocked Phase 2 entirely for no code-shape reason).
- **Pros:** Zero new runtime dependencies; every domain client gets retry/timeout/logging/error-mapping for free; 48 tests cover the whole pipeline against a mocked HTTP layer.
- **Cons:** The auth and webhook-signature placeholders will need updating (and their tests adjusting) once real Surfboard docs/credentials are available.
- **Impact:** `backend/src/integrations/surfboard/{client,middleware,models,mappers,utils,errors}/`, `backend/tests/integrations/surfboard/`.
- **Status:** Accepted
- **Owner:** Velan (Lead Architect direction), implemented by Claude
- **Cross-reference:** [docs/08_ARCHITECTURE_DECISIONS.md § ADR-018](../docs/08_ARCHITECTURE_DECISIONS.md#adr-018--surfboard-sdk-implementation-choices-phase-2)

### D-020 — UI dependency choices: google_fonts, flutter_svg, lucide_icons

- **Decision Number:** D-020
- **Date:** 2026-07-29
- **Decision:** Use `google_fonts` to load Inter (rather than bundling `.ttf` files under `frontend/assets/fonts/`), `flutter_svg` to render the Surfboard Payments brand mark (an SVG), and the `lucide_icons` package for the Lucide icon set specified in the design brief.
- **Reason:** These are the standard, actively-maintained Flutter-ecosystem packages for each need; versions were resolved live via `flutter pub add` (not guessed) to guarantee a working `pubspec.yaml` — `flutter_svg ^2.3.0`, `google_fonts ^8.2.0`, `lucide_icons ^0.257.0` at time of writing.
- **Alternatives Considered:** Bundling Inter `.ttf` files directly (avoids a runtime font-fetch on first launch in debug, but `google_fonts` caches after first load and is far simpler to maintain); a custom/manually-traced icon set instead of `lucide_icons`; converting the Surfboard SVG to a raster PNG to avoid the `flutter_svg` dependency (rejected — rasterizing would blur at large sizes/different pixel densities and risks distorting the mark, which the brand guidance explicitly prohibits).
- **Pros:** Minimal, well-supported dependency footprint; exact Lucide icon parity with the design brief; crisp brand-mark rendering at any size.
- **Cons:** `google_fonts` fetches Inter from Google's CDN on first run in a fresh environment (cached afterward) — if fully offline/hermetic builds become a requirement later, revisit bundling the font file directly instead.
- **Impact:** `frontend/pubspec.yaml`; `app/themes/app_typography.dart`; `core/widgets/branding/surfboard_logo.dart`.
- **Status:** Accepted, **amended 2026-07-29 (same day, Login-screen session)**
- **Owner:** Claude (implementation-level tooling choice during the premium-UI build session), Velan (project owner, ok to revisit)

**Amendment:** `lucide_icons 0.257.0` turned out to be unmaintained — its own `pubspec.yaml` declares `sdk: ">=2.12.0 <3.0.0"` (pre-Dart-3), and it defines `class LucideIconData extends IconData`, which fails to compile against the current Flutter SDK because `IconData` is now a `final class` (cannot be extended outside its own library — this restriction applies regardless of the extending package's own pinned language version). This wasn't caught by `flutter analyze` (clean) but *was* caught by `flutter test`'s actual compilation step — first evidence in this project that `analyze` alone is insufficient and the full mandatory sequence (§ workflow.md) matters. **Replaced with `lucide_icons_flutter ^3.1.15`** — same `LucideIcons` class name, same icon identifiers (verified `mail`, `lock`, `eye`, `eyeOff`, `search`, `scanLine`, `alertCircle`, `sparkles`, `cloudOff`, `inbox`, `layoutGrid`, `package`, `receipt`, `barChart3`, `settings` all present), same import path shape (`package:lucide_icons_flutter/lucide_icons.dart`), declares `sdk: ^3.0.0`, and implements icons as `static const IconData` fields (composition, not subclassing) — so it isn't exposed to the same `final class` restriction. All 7 files that imported the old package were updated to the new import path with no other code changes needed.

### D-021 — Floating (non-notched) FAB for a 5-item bottom nav

- **Decision Number:** D-021
- **Date:** 2026-07-29
- **Decision:** The bottom navigation renders all 5 destinations (Dashboard, Inventory, Billing, Analytics, Settings) evenly spaced with **no** Material notch, and the "Start New Sale" FAB floats centered *above* the bar (`FloatingActionButtonLocation.centerFloat`) rather than docking into a notch.
- **Reason:** The design brief specifies 5 bottom-nav destinations *and* a separate FAB — the classic Material `CircularNotchedRectangle` pattern assumes 4 items split 2-2 around a center notch, which doesn't divide evenly for 5 items without an awkward asymmetric gap.
- **Alternatives Considered:** Dropping one nav item to 4 + notch (rejected — the brief explicitly asks for 5 named destinations); hand-rolling a `CustomPainter` notch shaped for a 5-item bar (rejected as unnecessary complexity/risk for a cosmetic difference the floating variant achieves more simply).
- **Pros:** All 5 destinations stay evenly spaced and equally weighted; simpler, more robust implementation with no custom painting.
- **Cons:** Slightly less "physically docked" than a notched FAB — a purely cosmetic trade-off.
- **Impact:** `core/widgets/navigation/{app_bottom_nav_bar,app_main_scaffold}.dart`.
- **Status:** Accepted
- **Owner:** Claude (implementation-level design choice), Velan (project owner, ok to revisit)

---

## Future Decisions

_Append new entries here using the [Decision Template](#decision-template) above, in ascending `D-0XX` order. Do not renumber or delete existing entries — if a decision is reversed, mark the old entry's Status as `Superseded by D-0YY` and add the new entry, rather than editing history away._

_(No entries yet beyond D-001–D-021 above.)_
