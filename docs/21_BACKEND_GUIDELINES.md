# 21 — Backend Guidelines

> **New document, added during the Surfboard-alignment documentation pass.** This is the detailed backend layering contract that [07_CODING_RULES.md § 3](07_CODING_RULES.md#3-folder-conventions) points to. Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [02_ARCHITECTURE.md](02_ARCHITECTURE.md). Related: [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) for the physical tree this describes the rules for.

---

## 1. The Layer Chain

```
Route → Controller → Service → { Repository (Firebase) | Integration Client (Surfboard) } → { RTDB/Storage | Surfboard API }
                          ↕
                       Mapper
                          ↕
                      Validator (before Service is ever reached)
```

Strict one-directional dependency: a layer only calls the layer directly below it. A Controller never touches a Repository or an Integration Client directly. A Repository never calls an Integration Client, and vice versa — if a Service needs both a Firebase read and a Surfboard call to fulfill one request, it composes them itself; a Repository/Integration Client each stay single-responsibility for their own data source.

## 2. Controller

- **Responsibility:** parse the request (already validated by the time it gets here), call exactly one Service method (or a small composition of them), map the Service's return value to the standard response envelope via `utils/response.js`, and call `next(err)` on failure. Nothing else.
- **Never:** contains business rules, talks to Firebase or Surfboard directly, or exceeds ~40 lines (see [07_CODING_RULES.md § 4](07_CODING_RULES.md#4-component-size-limits)).
- **Lives in:** top-level `src/controllers/<resource>.controller.js` — one file per REST resource, regardless of which module(s) its Service calls into.

```js
// controllers/inventory.controller.js
const inventoryService = require('../modules/inventory/inventory.service');
const { sendSuccess } = require('../utils/response');
const asyncHandler = require('../utils/asyncHandler');

const adjustStock = asyncHandler(async (req, res) => {
  const result = await inventoryService.adjustStock(req.params.storeId, req.params.productId, req.body);
  sendSuccess(res, result);
});

module.exports = { adjustStock };
```

## 3. Service (Domain Service)

- **Responsibility:** the actual business rule. Owns validation *of business invariants* (not request shape — that's the Validator, § 6), orchestrates one or more Repositories and/or Integration Clients, and returns a plain domain object (per [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md)) — never a raw Firebase snapshot or raw Surfboard API response.
- **Never:** calls `firebase-admin` or an HTTP client directly. Always goes through its own module's Repository/Integration Client, or another module's Service (never another module's Repository — see § 8).
- **Lives in:** `src/modules/<domain>/<domain>.service.js`.
- **A Service composing both data sources** (the common case for anything touching a Sale) looks like:

```js
// modules/billing/billing.service.js
const inventoryService = require('../inventory/inventory.service');
const salesRepository = require('./sales.repository');
const paymentClient = require('../../integrations/surfboard/payment.client');

async function checkout(storeId, cart) {
  const validated = await inventoryService.validateAvailability(storeId, cart.items); // Firebase-owned
  const sale = await salesRepository.createPending(storeId, validated);               // Firebase-owned
  const payment = await paymentClient.createPaymentIntent(storeId, sale.grandTotal);   // Surfboard-owned
  return salesRepository.attachPaymentReference(sale.id, payment.id);
}

module.exports = { checkout };
```

## 4. Repository (Firebase-owned entities only)

- **Responsibility:** the *only* place a given Firebase-owned entity is read or written. Wraps the Firebase Admin SDK (`src/firebase/admin.js`) with entity-shaped methods (`get`, `create`, `update`, `query`) — no business logic, no validation beyond "is this shape writable."
- **Never:** exists for a Surfboard-owned entity (Merchant/Store/Device/Payment/Branding/Tips/PaymentMethods have no Repository — see § 5).
- **Lives in:** `src/modules/<domain>/<domain>.repository.js`, one per Firebase-owned entity that domain owns (see [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) for which entities are Firebase-owned).
- Multi-path writes that must succeed/fail together use `update()` with a multi-path object (see [07_CODING_RULES.md § 16](07_CODING_RULES.md#16-firebase-best-practices)) — this is where that rule is actually implemented.

```js
// modules/inventory/inventory.repository.js
const { getDb } = require('../../firebase/admin');

async function get(storeId, productId) {
  const snapshot = await getDb().ref(`inventory/${storeId}/${productId}`).once('value');
  return snapshot.val();
}

async function adjustQuantity(storeId, productId, delta, updatedBy) {
  const ref = getDb().ref(`inventory/${storeId}/${productId}`);
  return ref.transaction((current) => {
    if (!current) return current;
    return { ...current, quantity: current.quantity + delta, lastUpdatedBy: updatedBy };
  });
}

module.exports = { get, adjustQuantity };
```

## 5. Integration Client (Surfboard-owned entities only)

- **Responsibility:** the *only* place a given Surfboard-owned entity is called over HTTP. One client per Surfboard domain (`auth`, `merchant`, `payment`, `store`, `device`, `branding` — see [08_ARCHITECTURE_DECISIONS.md § ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split) for why Payment Methods/Tips fold into `store`/`payment` rather than getting their own file). No business logic — just request construction, auth header attachment, and response mapping via its Mapper.
- **Lives in:** `src/integrations/surfboard/<domain>.client.js` (already scaffolded — see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).
- **Never:** called directly from a Controller — always through the owning module's Service.

## 6. Mapper

- **Responsibility:** translate a wire-format object (a raw Firebase RTDB snapshot, or a raw Surfboard API response body) into the plain domain shape defined in [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), and back for writes. This is what keeps a Surfboard API's exact field-naming quirks from leaking into Service/Controller code.
- **Lives in:** co-located with what it maps for — `src/integrations/surfboard/<domain>.mapper.js` for Surfboard DTOs, `src/modules/<domain>/<domain>.mapper.js` for Firebase records that need shape translation (only add one if the raw Firebase shape genuinely needs translating — don't create a pass-through mapper for a Firebase record that's already domain-shaped).

```js
// integrations/surfboard/mappers/merchant.mapper.js
function toDomainMerchant(surfboardResponse) {
  return {
    id: surfboardResponse.merchant_id,
    businessName: surfboardResponse.business_name,
    status: surfboardResponse.onboarding_status,
    // ...
  };
}

module.exports = { toDomainMerchant };
```

## 7. Validator

- Unchanged from [07_CODING_RULES.md § 10](07_CODING_RULES.md#10-validation) and [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions): one `zod` schema per resource in `src/validators/`, applied via `validate.middleware.js` **before** the Controller is ever reached. A Validator checks request *shape* (types, required fields, ranges) — it never checks business invariants that require a data lookup (e.g. "does this SKU already exist" is a Service concern, not a Validator concern).

## 8. Cross-Module Rule

**A Service may call another module's Service. A Service may never call another module's Repository or Integration Client directly.** This is what keeps "the only place X is mutated" (per [07_CODING_RULES.md § 8](07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services)) enforceable — if `billing.service.js` needs inventory data, it calls `inventory.service.js`, never `inventory.repository.js` directly, so `inventory.service.js` retains the final say over its own invariants (e.g. "quantity never goes below zero") no matter who's asking.

## 9. Error Handling

- Every layer throws (never returns an error object or a boolean-false-for-failure). Repositories/Integration Clients throw plain `Error`s for transport-level failures; Services catch those and re-throw a typed `AppError` subclass (see `utils/errors.js`) carrying the right code for the situation:
  - A Firebase read/write failure the Service can't recover from → rethrow as `AppError` with `INTERNAL_ERROR` (the Repository's raw error is logged, not shown to the client).
  - A Surfboard API call that fails (4xx/5xx from Surfboard, timeout, or a signature/auth failure) → wrap as a new `SurfboardApiError extends AppError` with code `SURFBOARD_ERROR` (see [04_API_DOCUMENTATION.md § 1](04_API_DOCUMENTATION.md#1-conventions) for the code/status addition) — this distinguishes "our bug" from "Surfboard's API had a problem" in logs and in what the client is told.
  - A business-rule violation (insufficient stock, duplicate SKU) → the existing typed errors (`ConflictError`, or a future `InsufficientStockError`), unchanged from [07_CODING_RULES.md § 7](07_CODING_RULES.md#7-error-handling).
- `error.middleware.js` remains the single place any of the above becomes an HTTP response — no layer below it ever writes to `res` directly.

## 10. Logging

- Unchanged base convention from [07_CODING_RULES.md § 9](07_CODING_RULES.md#9-logging) (`pino`, one instance, `requestId` on every line). Additions for this layering:
  - Integration Client calls log the Surfboard endpoint/operation and duration at `debug`, and any failure at `warn`/`error` with the Surfboard error code if one was returned — **never log the request/response body verbatim** if it could contain a card/payment detail; log the domain IDs involved (`storeId`, `paymentId`) instead.
  - Repository calls don't need their own logging beyond what the Service already logs for the business event (e.g. "sale completed") — avoid a log line per Firebase read, which would drown the useful signal.

## 11. Testing

- **Repositories/Integration Clients:** tested against a Firebase emulator (Repositories) or a mocked HTTP layer (Integration Clients) — never production Firebase or the real Surfboard API, per [18_CONTRIBUTING.md § 5](18_CONTRIBUTING.md#5-testing-requirements).
- **Services:** the highest-value test surface — since a Service only depends on its Repository/Integration Client through a narrow interface (§ 12), tests construct a Service with fake/in-memory implementations of those dependencies and assert on business behavior (e.g. "checkout throws `INSUFFICIENT_STOCK` when cart qty exceeds inventory") without touching Firebase or Surfboard at all.
- **Controllers:** thin enough that they're covered by the route-level Supertest tests already established in `backend/tests/` (request in → expected envelope out), not unit-tested in isolation.

## 12. Dependency Injection

SurfPOS AI does **not** use a DI container/framework — that would be more machinery than a Node/Express API of this size needs. Instead:

- Every Service/Repository/Integration Client is a plain module exporting either a set of functions or a small class.
- A Service takes its Repository/Integration Client/other-Service dependencies as **constructor or factory parameters with the real implementation as the default**, e.g.:

```js
// modules/billing/billing.service.js
function createBillingService({
  inventoryService: injectedInventoryService = require('../inventory/inventory.service'),
  salesRepository: injectedSalesRepository = require('./sales.repository'),
  paymentClient: injectedPaymentClient = require('../../integrations/surfboard/payment.client'),
} = {}) {
  async function checkout(storeId, cart) { /* uses the injected deps above */ }
  return { checkout };
}

module.exports = createBillingService(); // default wiring used by the app
module.exports.createBillingService = createBillingService; // factory used by tests to inject fakes
```

- This gives tests (§ 11) a way to substitute fakes without a container, while production code gets the real wiring "for free" by default-parameter fallback. Simple singleton-style modules (Repositories, Integration Clients, anything with no further dependencies of its own) don't need this pattern — it only earns its keep where a Service's dependencies need to be swapped in a test.

## 13. Folder Ownership (Summary)

| Folder | Owns |
|---|---|
| `src/routes/` | Route → middleware chain wiring. No logic. |
| `src/controllers/` | Request-in/response-out. One file per REST resource. |
| `src/modules/<domain>/` | `<domain>.service.js` (always), `<domain>.repository.js` (only if `<domain>` owns a Firebase entity — see [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md)), `<domain>.mapper.js` (only if needed). |
| `src/integrations/surfboard/` | `<domain>.client.js` + `mappers/<domain>.mapper.js` — the only code that constructs a Surfboard HTTP request. |
| `src/validators/` | One `zod` schema per resource. |
| `src/middleware/` | Cross-cutting request pipeline (`auth`, `validate`, `error`, `rateLimit`). |
| `src/utils/` | Cross-cutting helpers with no domain knowledge (`logger`, `errors`, `response`, `asyncHandler`). |
| `src/constants/` | Single source of truth for status codes, error codes, messages, roles, permissions, routes, regex, env keys — see [07_CODING_RULES.md § 2](07_CODING_RULES.md#2-naming-conventions). |
| `src/types/` | JSDoc-only shared type definitions mirroring [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md). |
| `src/firebase/` | Firebase Admin SDK init only — every actual read/write goes through a Repository, never called from here or anywhere outside a Repository. |

---

**Next:** [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md) — the end-to-end lifecycles this layering implements.
