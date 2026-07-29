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
- **Impact:** `backend/src/modules/surfboard/`, `payments/{paymentId}` schema, `POST /webhooks/surfboard` — see [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md).
- **Status:** Accepted (integration pattern defined; exact API surface pending confirmation against official docs)
- **Owner:** Velan (project owner)
- **Cross-reference:** [docs/15_SURFBOARD_INTEGRATION.md](../docs/15_SURFBOARD_INTEGRATION.md); no prior formal ADR existed for this — consider adding one to [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md) (next available slot: ADR-010).

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

### D-012 — UI dependency choices: google_fonts, flutter_svg, lucide_icons

- **Decision Number:** D-012
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

### D-013 — Floating (non-notched) FAB for a 5-item bottom nav

- **Decision Number:** D-013
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

_(No entries yet beyond D-001–D-013 above.)_
