# 07 — Coding Rules

> **This file is Claude's (and every developer's) permanent coding constitution for this repository.** When writing code in this project, these rules override generic defaults. Read alongside [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md) (which points back here) before starting any implementation work. Related: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md), [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md).

---

## 1. Code Style

- **Dart/Flutter:** `dart format` is authoritative; `flutter_lints`/`analysis_options.yaml` must pass with zero warnings before a change is considered done.
- **Node.js/Express:** Prettier + ESLint (Airbnb-base or equivalent, finalized in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) once tooling is set up) — no code merges with lint errors.
- No commented-out code left in commits. Delete it — git history is the record, not a code comment.
- No `console.log`/`print` left in committed code — use the logging convention in §9.

## 2. Naming Conventions

| Context | Convention | Example |
|---|---|---|
| Dart classes, enums, widgets | `PascalCase` | `InventoryListScreen`, `SaleStatus` |
| Dart variables, functions, params | `camelCase` | `fetchProducts()`, `merchantId` |
| Dart file names | `snake_case.dart` | `inventory_list_screen.dart` |
| Node classes | `PascalCase` | `class SalesService` |
| Node variables, functions | `camelCase` | `calculateSaleTotal()` |
| Node file names | `kebab-case.js` (suffixed by layer) | `sales.controller.js`, `sales.service.js` |
| REST routes | `/kebab-case`, plural nouns | `/invoice-scans`, `/api/v1/sales` |
| Firebase RTDB nodes/fields | `camelCase`, plural node names | `products`, `sellingPrice` — see [03_DATABASE_DESIGN.md § 6](03_DATABASE_DESIGN.md#6-naming-conventions) |
| Environment variables | `SCREAMING_SNAKE_CASE` | `GEMINI_API_KEY` |

Booleans read as a question: `isActive`, `hasLowStock`, `canEditInventory` — never `active` or `flag`.

## 3. Folder Conventions

Full tree in [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md). Non-negotiable rules:

- **Flutter:** feature-first (`lib/features/<feature>/{data,domain,presentation}`), never "type-first" (no top-level `screens/`, `models/` catch-all folders spanning unrelated features).
- **Node:** layered (`routes/ → controllers/ → services/`), one file per resource per layer (`products.routes.js`, `products.controller.js`, `products.service.js`). A controller **never** talks to Firebase directly — only through a service.
- Shared/reusable code lives in `lib/shared/` (Flutter) or `src/utils/` + `src/services/` (Node) — see §8.
- Tests mirror the source tree (e.g. `test/features/inventory/...` mirrors `lib/features/inventory/...`).

## 4. Component Size Limits

- **Flutter widgets:** a single `build()` method should not exceed ~80 lines. If it does, extract sub-widgets. A screen file (including its private widgets) should stay under ~350 lines — beyond that, split into separate widget files under the feature's `presentation/widgets/` folder.
- **Node controllers:** a controller function handles request parsing, calling one (or a small composition of) service methods, and formatting the response — target under 40 lines. Business logic beyond that belongs in a service, not the controller.
- **Services:** a service file should stay focused on one resource/domain (e.g. `sales.service.js` owns sale creation/validation, not payment-provider HTTP calls — that's `surfboard.service.js`). If a service file exceeds ~300 lines, look for a sub-concern to extract.

## 5. Function Size Limits

- Target **≤ 30 lines** per function (Dart or JS). A longer function is a signal to extract a named helper — the extraction should make the *caller* more readable, not just move lines around.
- One function does one job. If describing a function requires "and," split it.
- Avoid more than 3 levels of nested conditionals/loops — invert with early returns/guard clauses instead.

## 6. Comments

- Default to **no comments** — clear naming and small functions should make code self-explanatory.
- Write a comment **only** when it explains a non-obvious *why*: a workaround for a specific external API quirk (e.g. "Surfboard requires amount in minor units"), a subtle invariant, or a deliberate deviation from the obvious approach.
- Never write a comment that restates what the code already says (`// increment i` above `i++`).
- No docstring blocks / multi-paragraph comments. One line max.
- No TODO comments left as the only record of pending work — track pending work in [10_TASKS.md](10_TASKS.md) instead, so it isn't lost inside a file.

## 7. Error Handling

- **Backend:** every controller is wrapped so thrown errors reach a single centralized `error.middleware.js`, which maps known error types to the standard error envelope and HTTP status from [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions). Never leak a raw stack trace or internal error message to the client in production.
- **Backend business errors** (insufficient stock, duplicate SKU, payment failure) are thrown as typed errors (e.g. `class InsufficientStockError extends AppError`) — never as generic `Error` or magic-string comparisons.
- **Flutter:** every backend/Firebase call site handles both the network-failure case and the backend error-envelope case, and surfaces a user-readable message (never a raw exception string) via the shared error-display pattern (e.g. a snackbar/toast component from [06_UI_UX_GUIDE.md § 9](06_UI_UX_GUIDE.md#9-design-system-component-inventory)).
- Never silently swallow an error (empty `catch`). At minimum, log it (§9); at most, handle and surface it.

## 8. Never Duplicate Logic — Always Reuse Services

- If two features need the same behavior (e.g. adjusting inventory, formatting a price, validating a phone number), it lives in **one** shared service/utility, imported by both — never copy-pasted.
- Inventory changes **only** happen through `inventory.service.js`, regardless of whether the trigger is a manual adjustment, a completed sale, or a confirmed invoice scan (see [05_FEATURES.md § 4](05_FEATURES.md#4-inventory-management)). No feature is allowed to write to the `inventory` node directly.
- Sale total/tax computation exists in exactly one place (`sales.service.js`) and is used both to validate incoming carts and to render totals — the client's locally computed total is for display only and is never trusted as the source of truth (see [02_ARCHITECTURE.md § 9](02_ARCHITECTURE.md#9-design-principles)).
- Before writing a new utility/service function, search the codebase for an existing one that already does it (or nearly does it) and extend/reuse rather than re-implement.

## 9. Logging

- **Backend:** structured logging (JSON) via a single logger instance (e.g. `pino`/`winston`, finalized in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)) — never bare `console.log`. Every log line includes at minimum: timestamp, level, `requestId`, and (when available) `merchantId`.
- Log levels used with intent: `error` (needs attention), `warn` (unexpected but handled), `info` (significant business events — sale completed, payment failed, invoice scan confirmed), `debug` (verbose, disabled in production).
- **Never log:** secrets, full card/payment payloads, raw Firebase service-account credentials, or full customer PII beyond what's operationally necessary.
- **Flutter:** use a single wrapped logger for debug-only diagnostic output; no logging of PII or tokens even in debug builds.

## 10. Validation

- Every backend endpoint validates its request body/query against an explicit schema (e.g. `zod`/`Joi` — finalized in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)) **before** any service/database call. Validation lives in a dedicated `validations/` layer, not inline in controllers (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).
- Client-side (Flutter) validation exists only for immediate user feedback (e.g. "phone number required") — it is never a substitute for backend validation.
- Every numeric business value (price, quantity, tax rate) is validated for range/sign server-side, regardless of what the client sends.

## 11. Security

- No secret (Gemini API key, Surfboard API key/secret, Firebase service-account JSON) is ever committed to the repo or bundled into the Flutter app — backend environment variables only (see [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md)).
- Every backend route (except the two explicitly public ones in [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions)) verifies the Firebase ID token before doing anything else.
- Every backend handler re-checks that the authenticated user's `merchantId`/`storeId`/`role` actually owns/permits the resource being accessed — a valid token alone is never sufficient authorization for someone else's data.
- Firebase Security Rules are treated as a **second, independent** enforcement layer, not a replacement for backend checks (defense in depth — see [02_ARCHITECTURE.md § 11](02_ARCHITECTURE.md#11-security)).
- All third-party HTTP calls (Surfboard, Gemini, OCR provider) use HTTPS, verify webhook signatures where applicable (see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)), and time out rather than hang indefinitely.

## 12. Performance

- **Flutter:** `const` widgets wherever possible; avoid rebuilding large widget subtrees for small state changes (scope Riverpod providers narrowly); paginate any list that can exceed ~50 items (products, sales history).
- **Backend:** never run an unbounded RTDB read (`.once('value')` on a whole large node) — always scope reads by `merchantId`/`storeId` and index-backed queries per [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes).
- Analytics are **precomputed**, never calculated live from raw sales on every request (see [02_ARCHITECTURE.md § 10](02_ARCHITECTURE.md#10-scalability)).
- AI (OCR/Gemini) calls are async/background jobs with a status field, never a request the user has to sit and wait on (see [05_FEATURES.md § 6](05_FEATURES.md#6-ai-invoice-scanner)).

## 13. Flutter Best Practices

- State management: Riverpod (see [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)) — no mixing in a second state-management library "because it's convenient for one screen."
- Business logic (price calculation, validation, matching) lives in `domain`/service classes, never inside a widget's `build()` method or button `onPressed` closure — see §14.
- Keep widgets stateless wherever possible; use `StatefulWidget`/local state only for pure UI concerns (animation controllers, text field focus) — actual app state goes through Riverpod.
- Use `go_router` for all navigation; no raw `MaterialPageRoute` scattered across features.

## 14. Keep Business Logic Out of the UI

- A widget's job is: render state, capture input, call a provider/controller method. It never itself computes a sale total, decides whether stock is sufficient, or decides whether an AI match confidence is "good enough" — those decisions live in domain/service code that can be tested without a widget tree.
- This applies symmetrically on the backend: a controller's job is request-in/response-out; it never contains the actual business rule beyond calling the relevant service.
- Rule of thumb: if a piece of logic would need to be tested, it should be in a plain Dart/JS class or function, not inside a widget or controller.

## 15. Node.js Best Practices

- Async/await throughout — no mixed callback style, no unhandled promise rejections (enforced via ESLint rule).
- Environment config loaded and validated once at boot (`config/index.js`) — fail fast on startup if a required env var is missing, rather than failing on first use deep in a request.
- One Express app instance (`app.js`), server bootstrap separate (`server.js`) — keeps the app testable without binding a port.
- Idempotency: webhook handlers (`POST /webhooks/surfboard`) must be safe to receive the same event twice (check/record event ID) since providers commonly retry.

## 16. Firebase Best Practices

- Every RTDB write goes through a service function, never directly from a controller — so validation/business rules can't be bypassed by a future new endpoint (see §8).
- Multi-node writes that must succeed/fail together use `update()` with a multi-path object (atomic across paths) rather than sequential separate writes.
- `.indexOn` is declared for every field used in `orderByChild`/`equalTo` — see [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes) — un-indexed queries are not acceptable in production code.
- Security Rules are version-controlled (`database.rules.json` in the repo) and reviewed like code — never edited ad hoc only in the Firebase console.
- Firebase Storage uploads are size/type-validated server-side before acceptance (e.g. invoice images: image types only, reasonable max size).

---

**Next:** [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) — the recorded rationale behind the choices these rules assume.
