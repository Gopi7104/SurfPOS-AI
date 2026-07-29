# 08 — Architecture Decision Records (ADRs)

> This file is the permanent decision log. **Every future significant decision — not just the founding ones below — must be appended here**, never overwritten. Related: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md).

**Format:** each entry has a Status, Context, Decision, Consequences, and Revisit trigger. Status is one of `Proposed`, `Accepted`, `Superseded by ADR-00X`.

---

## ADR-001 — Why Flutter for the frontend

- **Status:** Accepted
- **Context:** SurfPOS AI must ship for both Android and iOS, mobile-first, with a UI-heavy feature set (scanner, camera capture, real-time listeners) and a small initial engineering team.
- **Decision:** Use Flutter (Dart) as the single frontend codebase for Android and iOS.
- **Consequences:** One codebase instead of two native ones; strong first-party camera/barcode plugin ecosystem; excellent first-party Firebase SDK support (`firebase_auth`, `firebase_database`, `firebase_storage`). Trade-off: Dart is a smaller hiring pool than JS/TS or Kotlin/Swift alone, and any deep native-platform-specific feature requires a platform channel.
- **Revisit if:** the product needs deep native-only capability Flutter can't reach performantly, or a web/desktop client becomes priority (Flutter Web remains an option — see [01_PROJECT_OVERVIEW.md § Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope)).

## ADR-002 — Why Firebase (Auth, Realtime Database, Storage) over a custom backend datastore

- **Status:** Accepted
- **Context:** Target customers are small retailers who cannot manage servers, backups, or database administration. Real-time UI updates (live inventory, live sale status) are core to the product feel.
- **Decision:** Use Firebase Authentication, Realtime Database, and Storage as the entire data platform, with no separate SQL/NoSQL database.
- **Consequences:** Zero database-ops burden; built-in real-time sync to the client "for free"; tight Firebase Auth ↔ RTDB Security Rules integration. Trade-off: RTDB has no complex/relational queries — every access pattern must be designed into the tree shape up front (see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)), and RTDB has practical per-instance scaling ceilings that eventually require sharding by merchant/region.
- **Revisit if:** query complexity outgrows what denormalization can reasonably support, or a single RTDB instance becomes a throughput bottleneck (mitigation already designed in via `merchantId`/`storeId` partitioning — see [02_ARCHITECTURE.md § 10](02_ARCHITECTURE.md#10-scalability)).

## ADR-003 — Why Node.js + Express for the backend

- **Status:** Accepted
- **Context:** The backend's job is orchestration (Firebase Admin SDK, Gemini API, OCR, Surfboard Payments) rather than heavy compute — I/O-bound, not CPU-bound.
- **Decision:** Node.js + Express.js as a thin, stateless REST API layer.
- **Consequences:** JavaScript/TypeScript on both "server logic" and (loosely, via Dart's similar async idioms) frontend reasoning; huge ecosystem for HTTP clients/SDKs (Firebase Admin, Google APIs, payment SDKs); naturally async, well suited to orchestrating multiple external calls per request (OCR → Gemini → DB write). Trade-off: Node is not ideal for CPU-heavy work — if OCR/image processing ever needs to run in-process rather than via an external API, that workload should be isolated (worker process/queue), not run inline in the request thread.
- **Revisit if:** a CPU-bound workload needs to move in-process — isolate it rather than abandoning Node/Express for the whole API.

## ADR-004 — Why AI OCR + Gemini for invoice scanning (vs. manual entry only)

- **Status:** Accepted
- **Context:** Manual invoice re-entry is the single biggest identified time cost for the target customer (see [01_PROJECT_OVERVIEW.md § Business Problem](01_PROJECT_OVERVIEW.md#3-business-problem)).
- **Decision:** Photograph the invoice → OCR extracts raw text → Gemini structures it into line items and matches against the product catalog → merchant reviews/confirms before anything is committed to inventory.
- **Consequences:** Removes the manual re-typing step entirely for the common case; the "AI proposes, human confirms" pattern (see [02_ARCHITECTURE.md § 9](02_ARCHITECTURE.md#9-design-principles)) keeps AI mistakes from silently corrupting inventory/cost data. Trade-off: OCR/Gemini accuracy varies with photo quality/invoice format, so a review step is mandatory (not optional) in Phase 1 — full automation is explicitly deferred (see [05_FEATURES.md § 6 Future Improvements](05_FEATURES.md#6-ai-invoice-scanner)).
- **Revisit if:** extraction accuracy is measured (post-launch) to be reliably high enough for an opt-in auto-confirm mode above a confidence threshold.

## ADR-005 — Why smartphone-only POS (no dedicated terminal/hardware requirement)

- **Status:** Accepted
- **Context:** Dedicated POS hardware (terminal, external barcode scanner, receipt printer) is a major upfront cost barrier for the target small-retailer customer.
- **Decision:** The phone's own camera is the barcode scanner and invoice-scan camera; payment is accepted through whatever Surfboard-supported method works from/with the phone (tap-to-pay, UPI/QR, or a lightweight connected reader where Surfboard requires one); receipts are digital-first.
- **Consequences:** Zero-hardware onboarding — a merchant can start selling with only a phone; lower total cost of ownership than any hardware-based competitor. Trade-off: reliant on the phone camera's barcode-read reliability and on whichever physical payment-acceptance method Surfboard actually requires for card-present transactions (may still need a small Surfboard-provided reader depending on their supported rails — confirm and document in [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) once integrated).
- **Revisit if:** optional hardware add-ons (printer, external scanner) are prioritized — already designed as additive, not required (see [01_PROJECT_OVERVIEW.md § Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope)).

## ADR-006 — Why cloud architecture (no local/offline-first-by-default design)

- **Status:** Accepted
- **Context:** The product promise is "no local server, no local backup responsibility for the merchant," and real-time cross-device sync (e.g. dashboard updating live as a sale happens) is a core value prop.
- **Decision:** Firebase RTDB is the single source of truth; the backend is stateless and cloud-hosted; the client is online-first, with the specific, scoped offline allowances documented in [02_ARCHITECTURE.md § 12](02_ARCHITECTURE.md#12-offline-strategy) (cached catalog/barcode lookup, cart-building) rather than a full offline-first architecture.
- **Consequences:** Simpler architecture (no local database, no complex conflict-resolution/sync engine needed for Phase 1); merchant never manages a backup. Trade-off: checkout/payment genuinely requires connectivity in Phase 1 — this is a known, explicit limitation, not an oversight (see [10_TASKS.md](10_TASKS.md) for when offline checkout queueing is scheduled).
- **Revisit if:** merchant feedback shows connectivity gaps are a frequent blocker at the point of sale specifically (not just for dashboard/reports) — triggers the offline-sale-queueing work already scoped in Future Scope.

## ADR-007 — State management: Riverpod (Flutter)

- **Status:** Proposed (confirm before Phase 1 implementation begins)
- **Context:** A feature-first Flutter app with real-time Firebase listeners needs a state-management approach that scopes rebuilds narrowly and testable outside the widget tree (see [07_CODING_RULES.md § 14](07_CODING_RULES.md#14-keep-business-logic-out-of-the-ui)).
- **Decision:** Riverpod, with `go_router` for navigation.
- **Consequences:** Compile-safe provider scoping, easy testing of business logic without a widget tree, good fit for feature-first folder structure. Trade-off: another library API surface for new contributors to learn.
- **Revisit if:** the team has strong existing expertise in an alternative (e.g. Bloc) that outweighs the switch cost — decide **before** Phase 1 screens are built, since retrofitting state management later is expensive.

## ADR-008 — Multi-tenant data model from day one, multi-store UI deferred

- **Status:** Accepted
- **Context:** Retrofitting a multi-tenant/multi-store schema after data exists is expensive and risky; building multi-store UI before there's a validated single-store product is premature scope.
- **Decision:** Every schema node is already keyed/scoped by `merchantId` and, where relevant, `storeId` (see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)), but Phase 1 only exposes single-store UI, with one store auto-created at registration.
- **Consequences:** No future data migration needed to support multi-store; Phase 1 scope stays small. Trade-off: a small amount of "unused" structure (the `storeId` layer) exists before it's exercised by UI.
- **Revisit if:** never — this is intentionally permanent; only the UI exposing multi-store is a future task (see [10_TASKS.md](10_TASKS.md)).

## ADR-009 — Pending decisions to record here once made

The following are intentionally **not yet decided** and must be logged as new ADR entries (ADR-010+) the moment they are:

- Final choice of OCR provider/library (on-device ML Kit vs. a cloud OCR API) — see [16_AI_MODULE.md](16_AI_MODULE.md).
- Final choice of backend validation library (`zod` vs. `Joi`) and logging library (`pino` vs. `winston`) — see [07_CODING_RULES.md §§ 9–10](07_CODING_RULES.md#9-logging).
- Exact Surfboard Payments API surface once official integration docs/credentials are available — see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).
- Final production font family for the design system — see [06_UI_UX_GUIDE.md § 3](06_UI_UX_GUIDE.md#3-typography).
- Where Gemini-generated insights are cached/stored in the schema — see [05_FEATURES.md § 12](05_FEATURES.md#12-analytics--ai-business-insights).

---

**Next:** [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) — running log of prompts given to Claude and the resulting decisions.
