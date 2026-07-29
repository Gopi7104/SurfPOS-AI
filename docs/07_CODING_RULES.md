# 07 — Coding Rules

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** This file is Claude's (and every developer's) permanent coding constitution for this repository. Read alongside [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md) and, for backend layering detail, [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) before starting any implementation work. Related: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md), [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md).

---

## 1. Code Style

- **Dart/Flutter:** `dart format` is authoritative; `flutter_lints`/`analysis_options.yaml` must pass with zero warnings.
- **Node.js/Express:** ESLint flat config + Prettier (see [08_ARCHITECTURE_DECISIONS.md § ADR-012](08_ARCHITECTURE_DECISIONS.md#adr-012--lintformat-tooling-eslint-flat-config--prettier-not-airbnb-base)) — no code merges with lint errors.
- No commented-out code left in commits. Delete it — git history is the record, not a code comment.
- No `console.log`/`print` left in committed code — use the logging convention in § 9.

## 2. Naming Conventions

| Context | Convention | Example |
|---|---|---|
| Dart classes, enums, widgets | `PascalCase` | `InventoryListScreen`, `SaleStatus` |
| Dart variables, functions, params | `camelCase` | `fetchProducts()`, `storeId` |
| Dart file names | `snake_case.dart` | `inventory_list_screen.dart` |
| Node classes | `PascalCase` | `class BillingService` |
| Node variables, functions | `camelCase` | `calculateSaleTotal()` |
| Node file names | `kebab-case.js` (suffixed by layer) | `sales.controller.js`, `inventory.service.js`, `inventory.repository.js`, `merchant.client.js` |
| REST routes | `/kebab-case`, plural nouns | `/invoice-scans`, `/api/v1/sales` |
| Firebase RTDB nodes/fields | `camelCase`, plural node names | `products`, `invoiceScans` — see [03_DATABASE_DESIGN.md § 6](03_DATABASE_DESIGN.md#6-naming-conventions) |
| Surfboard reference IDs | `camelCase` suffix `Id` (opaque strings, not Firebase push keys) | `merchantId`, `storeId`, `surfboardPaymentId` — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle) |
| Environment variables | `SCREAMING_SNAKE_CASE` | `SURFBOARD_API_KEY` |

Booleans read as a question: `isActive`, `hasLowStock`, `canEditInventory` — never `active` or `flag`.

## 3. Folder Conventions

Full tree: [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md). Full layer contract (Controller/Service/Repository/Integration Client/Mapper/Validator): [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md). Non-negotiable rules:

- **Flutter:** feature-first (`lib/features/<feature>/{data,domain,presentation}`), never "type-first."
- **Node:** layered — `routes/ → controllers/ → services/modules/`. A controller **never** talks to Firebase or Surfboard directly — only through a Service, which itself only reaches Firebase through a Repository and Surfboard through an Integration Client (see [21_BACKEND_GUIDELINES.md §§ 2–5](21_BACKEND_GUIDELINES.md#2-controller)).
- Shared/reusable code lives in `lib/core/` (Flutter) or `src/utils/` + `src/constants/` (Node) — see § 8.
- Tests mirror the source tree.

## 4. Component Size Limits

- **Flutter widgets:** `build()` ≤ ~80 lines; a screen file ≤ ~350 lines.
- **Node controllers:** under 40 lines — parse request, call one Service method, format response.
- **Services:** stay focused on one domain (e.g. `billing.service.js` owns Sale creation/validation, not Surfboard HTTP calls — that's `integrations/surfboard/payment.client.js`). If a Service file exceeds ~300 lines, look for a sub-concern to extract.

## 5. Function Size Limits

- Target **≤ 30 lines** per function. A longer function is a signal to extract a named helper.
- One function does one job.
- Avoid more than 3 levels of nested conditionals/loops — invert with early returns/guard clauses.

## 6. Comments

- Default to **no comments** — clear naming and small functions should make code self-explanatory.
- Write a comment **only** when it explains a non-obvious *why*.
- No docstring blocks / multi-paragraph comments. One line max.
- No TODO comments left as the only record of pending work — track in [10_TASKS.md](10_TASKS.md) instead.

## 7. Error Handling

- Every controller is wrapped so thrown errors reach `error.middleware.js`, which maps known error types to the standard error envelope and HTTP status from [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions).
- Backend business errors are thrown as typed errors extending `AppError` (see [21_BACKEND_GUIDELINES.md § 9](21_BACKEND_GUIDELINES.md#9-error-handling)) — never generic `Error` or magic-string comparisons.
- **A Surfboard API failure is always wrapped as `SurfboardApiError` (code `SURFBOARD_ERROR`), never surfaced to the client as a raw upstream error or silently treated as `INTERNAL_ERROR`** — this is new in this pass and matters because so much more of the system now depends on Surfboard responding.
- Never silently swallow an error (empty `catch`). At minimum, log it (§ 9).

## 8. Never Duplicate Logic — Always Reuse Services

- If two features need the same behavior, it lives in **one** shared service/utility, imported by both.
- Inventory changes **only** happen through `inventory.service.js`. Sale total/tax computation exists in exactly one place (`billing.service.js`).
- **Never persist a duplicate of a Surfboard-owned object in Firebase** — Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods are fetched live through their Integration Client every time, never cached as a Firebase record (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). If you're tempted to add a field to a Firebase node to "avoid an extra API call," that's the rule this line exists to stop — solve it with in-process caching at the Integration Client layer instead (see [21_BACKEND_GUIDELINES.md § 5](21_BACKEND_GUIDELINES.md#5-integration-client-surfboard-owned-entities-only)), never with Firebase persistence.
- A Service never reaches into another module's Repository or Integration Client directly — always through that module's Service (see [21_BACKEND_GUIDELINES.md § 8](21_BACKEND_GUIDELINES.md#8-cross-module-rule)).
- Before writing a new utility/service function, search the codebase for an existing one that already does it.

## 9. Logging

- Structured logging (JSON) via a single `pino` instance — never bare `console.log`. Every log line includes: timestamp, level, `requestId`, and (when available) `merchantId`.
- Log levels used with intent: `error`, `warn`, `info` (significant business events), `debug`.
- **Never log:** secrets, full card/payment payloads, raw Firebase service-account credentials, full customer PII, or a Surfboard request/response body that could contain payment details — log the domain IDs involved (`storeId`, `surfboardPaymentId`) instead (see [21_BACKEND_GUIDELINES.md § 10](21_BACKEND_GUIDELINES.md#10-logging)).
- **Flutter:** single wrapped logger for debug-only diagnostic output; no logging of PII or tokens.

## 10. Validation

- Every backend endpoint validates its request body/query against an explicit `zod` schema **before** any Service/Repository/Integration Client call. Validation lives in `src/validators/`, not inline in controllers.
- Client-side (Flutter) validation exists only for immediate feedback.
- Every numeric business value is validated for range/sign server-side.

## 11. Security

- No secret (Gemini API key, Surfboard API key/secret, Firebase service-account JSON) is ever committed or bundled into the Flutter app — backend environment variables only.
- Every backend route (except the three explicitly public ones in [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions)) verifies the Firebase ID token before doing anything else.
- Every backend handler re-checks that the authenticated user's `merchantId`/`storeId`/`role` **reference** actually owns/permits the resource being accessed — a valid token alone is never sufficient authorization.
- Firebase Security Rules are a second, independent enforcement layer **for application data only** — they have nothing to say about Merchant/Store/Device/Payment data, since that never reaches Firebase (see [03_DATABASE_DESIGN.md § 8](03_DATABASE_DESIGN.md#8-security-rules-summary)). Authorization for Surfboard-owned resources is enforced entirely in the backend's Integration Layer + Surfboard's own API-level auth.
- All third-party HTTP calls (Surfboard, Gemini, OCR provider) use HTTPS, verify webhook signatures where applicable, and time out rather than hang indefinitely.

## 12. Performance

- **Flutter:** `const` widgets wherever possible; paginate any list that can exceed ~50 items.
- **Backend (Firebase):** never run an unbounded RTDB read — always scope reads by `merchantId`/`storeId` reference and index-backed queries per [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes).
- **Backend (Surfboard):** every Integration Client call is a network round-trip to an external system — batch/parallelize where Surfboard's API allows it, and never call Surfboard synchronously inside a tight loop (e.g. never fetch Store details once per cart item). Short-lived in-process caching is allowed for read-heavy, slow-changing data (e.g. Payment Methods); RTDB persistence is not (see § 8).
- Analytics are **precomputed**, never calculated live from raw sales on every request.
- AI (OCR/Gemini) calls are async/background jobs with a status field.

## 13. Flutter Best Practices

- State management: Riverpod (see [08_ARCHITECTURE_DECISIONS.md § ADR-007](08_ARCHITECTURE_DECISIONS.md#adr-007--state-management-riverpod-flutter)) — still Proposed, unaffected by this pass.
- Business logic lives in `domain`/service classes, never inside a widget's `build()` method.
- Keep widgets stateless wherever possible.
- Use `go_router` for all navigation. **The Flutter app no longer talks to Firebase SDKs directly for any data** (see [02_ARCHITECTURE.md § 2](02_ARCHITECTURE.md#2-frontend-flutter)) — a single `ApiClient` (`dio`) wrapper is the only network layer.

## 14. Keep Business Logic Out of the UI

- A widget's job is: render state, capture input, call a provider/controller method.
- This applies symmetrically on the backend: a Controller's job is request-in/response-out; it never contains the actual business rule beyond calling the relevant Service.
- Rule of thumb: if a piece of logic would need to be tested, it should be in a plain Dart/JS class or function, not inside a widget or controller.

## 15. Node.js Best Practices

- Async/await throughout — no mixed callback style, no unhandled promise rejections.
- Environment config loaded and validated once at boot (`config/index.js`) — fail fast on startup if a required env var is missing.
- One Express app instance (`app.js`), server bootstrap separate (`server.js`).
- Idempotency: webhook handlers (`POST /webhooks/surfboard`) must be safe to receive the same event twice.
- **Dependency injection:** Services accept their Repository/Integration Client/other-Service dependencies as constructor/factory parameters defaulting to the real implementation — no DI framework/container (see [21_BACKEND_GUIDELINES.md § 12](21_BACKEND_GUIDELINES.md#12-dependency-injection)).

## 16. Firebase Best Practices (Application Data Only)

- Every RTDB write goes through a Repository, never directly from a Controller or Service.
- Multi-node writes that must succeed/fail together use `update()` with a multi-path object.
- `.indexOn` is declared for every field used in `orderByChild`/`equalTo` — see [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes).
- Security Rules are version-controlled (`database.rules.json`) and reviewed like code.
- Firebase Storage uploads are size/type-validated server-side before acceptance.
- **These rules apply only to the application-data entities in [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle) (right column).** There is no Repository, no RTDB node, and no Security Rule for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods — see § 17.

## 17. Surfboard Integration Best Practices (Surfboard-Owned Entities Only)

- Every Surfboard HTTP call goes through an Integration Client (`src/integrations/surfboard/<domain>.client.js`), never directly from a Controller or Service.
- Every Integration Client shares one base request/auth implementation (`surfboardClient.base.js`) — a credential or auth-scheme change is a one-file fix.
- Every Surfboard response is passed through a Mapper before a Service sees it — Services and Controllers work with the plain domain shapes in [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), never raw Surfboard field names.
- Webhook signature verification is mandatory before any data from `POST /webhooks/surfboard` is trusted (see [15_SURFBOARD_INTEGRATION.md § 7](15_SURFBOARD_INTEGRATION.md#7-webhooks)).
- No Surfboard-owned entity is ever written to Firebase — see § 8 and [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle).

---

**Next:** [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) — the recorded rationale behind the choices these rules assume.
