# 04 — API Documentation

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md). Related: [16_AI_MODULE.md](16_AI_MODULE.md), [07_CODING_RULES.md](07_CODING_RULES.md).
>
> **Ownership legend used throughout this file:** 🔵 = backend proxies live to Surfboard (no Firebase persistence of the response). 🟢 = backend reads/writes Firebase application data. See [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase).

---

## 1. Conventions

- **Base URL:** `https://api.surfpos.ai/api/v1` (placeholder domain — actual deployment URL set in environment config, see [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md)).
- **Format:** JSON request/response bodies, `Content-Type: application/json`, except upload endpoints (`multipart/form-data`).
- **Authentication:** every endpoint except `POST /auth/signup`, `POST /auth/login`, `POST /auth/register`, `POST /webhooks/surfboard`, and `GET /health` (see [§ 14](#14-health--infra)) requires:
  ```
  Authorization: Bearer <Firebase ID Token>
  ```
  Verified server-side via Firebase Admin SDK in `auth.middleware.js`. Identity remains a Firebase Authentication concern regardless of which system of record owns the resource being requested.
- **Standard success envelope:**
  ```json
  { "success": true, "data": { ... } }
  ```
- **Standard error envelope:**
  ```json
  { "success": false, "error": { "code": "VALIDATION_ERROR", "message": "..." , "details": [] } }
  ```
- **Pagination** (list endpoints): query params `?limit=20&cursor=<opaque>`, response includes `"nextCursor"`.
- **Standard HTTP status codes:**

| Status | Meaning |
|---|---|
| 200 | Success |
| 201 | Resource created |
| 400 | Validation error |
| 401 | Missing/invalid auth token |
| 403 | Authenticated but not authorized for this resource (wrong merchant/store/role) |
| 404 | Resource not found |
| 409 | Conflict (e.g. duplicate SKU/barcode) |
| 422 | Business-rule violation (e.g. insufficient stock) |
| 429 | Rate limited |
| 502 | Upstream Surfboard API failure (new — see § below) |
| 500 | Unhandled server error |

- **Standard error codes:** `VALIDATION_ERROR`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `INSUFFICIENT_STOCK`, `SURFBOARD_ERROR` (new — a Surfboard API call failed, timed out, or returned an unexpected shape; see [21_BACKEND_GUIDELINES.md § 9](21_BACKEND_GUIDELINES.md#9-error-handling)), `AI_PROCESSING_ERROR`, `RATE_LIMITED`, `INTERNAL_ERROR`.

## 2. Auth & Merchant Onboarding

> **Roadmap Phase 3 (implemented) vs. Phase 4 (not yet implemented):** `POST /auth/signup`, `POST /auth/login`, `GET /auth/me`, `POST /auth/logout` below are Phase 3 — Firebase identity only, no Surfboard call, no Merchant/Store record. `POST /auth/register` is Phase 4 — full onboarding orchestration (Surfboard Merchant + Store creation) — and assumes the Firebase account already exists (created via `POST /auth/signup` or a future client-side Firebase SDK). See [ADR-020](08_ARCHITECTURE_DECISIONS.md#adr-020--application-client-authentication-endpoint-shape-phase-3).

### `POST /auth/signup` 🟢 — *Phase 3*
- **Purpose:** Create a new SurfPOS user (Firebase Auth account + `users/{uid}` profile). Default `role: "owner"`. Does **not** create a Merchant/Store — see `POST /auth/register` (Phase 4) for that.
- **Auth:** None.
- **Request:** `{ "email": "owner@example.com", "password": "supersecret", "displayName": "Jane Owner" }` — `displayName` optional.
- **Response (201):** `{ "user": { "uid", "email", "displayName", "role": "owner", "status": "active", "createdAt", "updatedAt" } }`
- **Validation:** `email` must be a valid email; `password` minimum 8 characters.
- **Errors:** `VALIDATION_ERROR` (400), `CONFLICT` (409, email already registered).

### `POST /auth/login` 🟢 — *Phase 3*
- **Purpose:** Verify a Firebase ID token (obtained client-side after Firebase sign-in) and return the caller's `users/{uid}` profile — a confirmation step distinct from the `authenticate` middleware used on every other protected route.
- **Auth:** None (the ID token is the payload being verified).
- **Request:** `{ "idToken": "firebase-id-token" }`
- **Response (200):** `{ "user": {...} }` (same shape as `POST /auth/signup`'s response).
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401, invalid/expired token), `NOT_FOUND` (404, token valid but no profile provisioned yet).

### `POST /auth/logout` 🟢 — *Phase 3*
- **Purpose:** Revoke the caller's Firebase refresh tokens. Already-issued ID tokens remain valid until their natural (short) expiry — this is not instant session kill-switch, see [ADR-020](08_ARCHITECTURE_DECISIONS.md#adr-020--application-client-authentication-endpoint-shape-phase-3).
- **Auth:** Required.
- **Response (200):** `{ "loggedOut": true }`
- **Errors:** `UNAUTHENTICATED` (401).

### `POST /auth/register` 🔵🟢 — *originally-planned Phase 4 shape, not implemented; deferred*
- **Purpose:** Complete owner-user profile creation after Firebase Auth sign-up, and create the Merchant + default Store **in Surfboard** (not Firebase), in one orchestrated call.
- **Status:** This is the *original* Phase 4 design. The pass that actually implemented Phase 4 re-scoped it to the `POST /merchant/applications` resource below instead (no Store creation, no `users/{uid}.merchantId` write) — see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4). This entry is kept as the still-possible future shape, not deleted, per this doc set's "maintained, not archived" convention.
- **Auth:** None (client passes the fresh ID token in the body for verification).
- **Request:**
  ```json
  {
    "idToken": "firebase-id-token",
    "businessName": "Blue Wave Surf Shop",
    "businessType": "retail",
    "contactPhone": "+46xxxxxxxxx",
    "address": { "line1": "...", "city": "...", "country": "SE" }
  }
  ```
- **Orchestration:** verify `idToken` → call `merchant.client.js` to create the Surfboard Merchant → call `store.client.js` to create the default Surfboard Store → write **only** `users/{uid}.merchantId`/`storeIds` references (Firebase). See [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle).
- **Response (201):** `{ "merchantId": "sb_merchant_xxx", "storeId": "sb_store_xxx", "onboardingStatus": "pending_verification" }`
- **Validation:** `businessName` required (min 2 chars), `contactPhone` required E.164 format, `idToken` must verify.
- **Errors:** `VALIDATION_ERROR` (400), `CONFLICT` (409, this UID already has a `merchantId`), `SURFBOARD_ERROR` (502, Merchant/Store creation failed upstream).

### `POST /merchant/applications` 🔵🟢 — *Phase 4 (implemented, wire format confirmed — see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction))*
- **Purpose:** Submit a merchant application — calls Surfboard's real Create Merchant API and tracks the result as Firebase-owned application metadata. A Store **is** created as part of this call (`controlFields.store`, required — SurfPOS is in-store-only, an onboarded merchant with no store can't process payments yet), but no `users/{uid}.merchantId`/`storeIds` reference is written (see [ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4)).
- **Auth:** Required.
- **Request:**
  ```json
  {
    "country": "SE",
    "organisation": {
      "corporateId": "1234567812",
      "legalName": "Blue Wave Surf Shop AB",
      "mccCode": "5941",
      "address": { "addressLine1": "Main St 1", "city": "Malmö", "countryCode": "SE", "postalCode": "211 34" },
      "phoneNumber": { "code": "46", "number": "701234567" },
      "email": "owner@example.com"
    },
    "store": {
      "name": "Blue Wave Surf Shop — Main",
      "email": "store@example.com",
      "phoneNumber": { "code": "46", "number": "701234567" },
      "address": { "addressLine1": "Main St 1", "city": "Malmö", "countryCode": "SE", "postalCode": "211 34" }
    }
  }
  ```
  `organisation.legalName`/`mccCode`/`phoneNumber`/`email` are optional (Surfboard requires them only for PF partners — SurfPOS always collects them anyway, since sending extra fields for a non-PF partner is harmless).
- **Response (201):** `{ "application": { "applicationId", "merchantId", "storeId", "applicationStatus": "APPLICATION_INITIATED", "applicationUrl" (the Surfboard-hosted KYB link), "shortLinkUrl", "submittedAt", "updatedAt" } }` — `merchantId`/`storeId` are usually `null` until the KYB flow completes (see `GET /merchant/applications/:id/status` below); Create Merchant's own response never carries a status.
- **Validation:** `country` 2-letter, `organisation.corporateId` required, `organisation.mccCode` (if provided) 4 digits, `organisation.address.{addressLine1,city,countryCode,postalCode}` required, `store.{name,email,phoneNumber,address}` all required.
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401), `CONFLICT` (409, an application already exists for this account), `SURFBOARD_ERROR` (502).

### `GET /merchant/applications/:id` 🟢 — *Phase 4 (implemented)*
- **Purpose:** Fetch the caller's own merchant application by `applicationId` — returns the last **cached** snapshot (from creation or the last `/status` refresh), not a live Surfboard call.
- **Auth:** Required — scoped to the caller's own application (there is no cross-user lookup path).
- **Response (200):** `{ "application": {...} }` (same shape as the `POST` response).
- **Errors:** `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no application, or `:id` doesn't match the caller's own).

### `GET /merchant/applications/:id/status` 🟢 — *Phase 4 (implemented — new, see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction))*
- **Purpose:** Poll Surfboard's real Check Application Status endpoint and refresh the cached record — the only way to observe KYB progress short of a webhook receiver (out of scope here).
- **Auth:** Required — same ownership scoping as `GET /merchant/applications/:id`.
- **Response (200):** `{ "application": { "applicationId", "merchantId", "storeId", "applicationStatus", "applicationUrl", "submittedAt", "updatedAt" } }` — `applicationStatus` is one of `APPLICATION_INITIATED`, `APPLICATION_STARTED`, `APPLICATION_SUBMITTED`, `APPLICATION_PENDING_INFORMATION`, `APPLICATION_SIGNED`, `APPLICATION_REJECTED`, `APPLICATION_COMPLETED`, `APPLICATION_EXPIRED`, `MERCHANT_CREATED` (`merchantId`/`storeId` only populate at `MERCHANT_CREATED`).
- **Errors:** `UNAUTHENTICATED` (401), `NOT_FOUND` (404), `SURFBOARD_ERROR` (502).

### `GET /merchant/applications` 🟢 — *Phase 4 (implemented)*
- **Purpose:** List the caller's own merchant application(s) — not a global/admin listing.
- **Auth:** Required.
- **Response (200):** `{ "applications": [...] }` (currently 0 or 1 items — one application per uid).
- **Errors:** `UNAUTHENTICATED` (401).

### `GET /auth/me` 🟢 — *Phase 3*
- **Purpose:** Fetch the authenticated user's app profile — `role` and `merchantId`/`storeIds` **references** (not the Merchant/Store objects themselves; call § 3 for those). `merchantId`/`storeIds` are absent until Phase 4 writes them.
- **Auth:** Required.
- **Response (200):** `{ "user": {...}, "role": "owner" }`
- **Errors:** `NOT_FOUND` (404, profile not provisioned — client should route to onboarding).

### `POST /auth/staff-invite` 🟢
- **Purpose:** Owner invites a staff member — a SurfPOS access-control concept, not a Surfboard one.
- **Auth:** Required, `role: owner` only.
- **Request:** `{ "phone": "+46xxxxxxxxx", "storeId": "sb_store_xxx" }`
- **Response (201):** `{ "inviteCode": "..." }`
- **Errors:** `FORBIDDEN` (403, non-owner), `VALIDATION_ERROR`.

## 3. Merchants & Stores

> All endpoints in this section proxy live to Surfboard. **Nothing here is persisted in Firebase** beyond the `merchantId`/`storeId` reference already written at registration (§ 2) — see [20_DOMAIN_MODEL.md §§ 2.1–2.2](20_DOMAIN_MODEL.md#21-merchant--surfboard-owned).

### `GET /merchants/:merchantId` 🔵 — *originally-planned Phase 5 shape, not implemented; deferred*
- **Purpose:** Fetch the current Merchant profile, live from Surfboard, by explicit `:merchantId`.
- **Status:** The pass that actually implemented Phase 5 re-scoped this to the caller-scoped `GET /merchant` below (no route param) — see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5). Kept documented, not deleted, per this doc set's "maintained, not archived" convention.
- **Auth:** Required; caller's `users/{uid}.merchantId` must match `:merchantId`.
- **Response (200):** Merchant object (§ 2.1 of [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md)), mapped from Surfboard's response by `merchant.mapper.js`.
- **Errors:** `FORBIDDEN`, `NOT_FOUND`, `SURFBOARD_ERROR`.

### `PATCH /merchants/:merchantId` 🔵 — *originally-planned Phase 5 shape, not implemented; deferred*
- **Purpose:** Update Merchant profile fields — proxied directly to Surfboard's Merchant API, by explicit `:merchantId`.
- **Status:** Re-scoped to `PATCH /merchant` below — see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5).
- **Auth:** Required, owner only.
- **Request:** Partial merchant object (`businessName`, `address`, `contactPhone`, `contactEmail`).
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`, `SURFBOARD_ERROR`.

### `GET /merchant` 🔵 — *Phase 5 (implemented, wire format confirmed — see [ADR-026](08_ARCHITECTURE_DECISIONS.md#adr-026--merchant-onboarding-api-contract-confirmed-phase-4-correction))*
- **Purpose:** Fetch the authenticated caller's own Merchant profile, live from Surfboard. No `:merchantId` param — the `merchantId` is resolved server-side from the caller's own `merchantApplications/{uid}.merchantId` (see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5)).
- **Auth:** Required.
- **Response (200):** `{ "merchant": { "id", "name", "companyId", "email", "phoneNumber", "logoUrl", "mccCode", "countryCode", "address" } }` — flat fields (Surfboard's Fetch Merchant Details response is not nested the way Create Merchant's request is), mapped from Surfboard's response by `merchant.mapper.js#toMerchantProfile()`. Note: **no `status` field** — Fetch Merchant Details doesn't return one; use `GET /merchant/status` below.
- **Errors:** `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no `merchantId` assigned yet — application still pending or not submitted), `SURFBOARD_ERROR` (502).

### `PATCH /merchant` 🔵 — *Phase 5 (implemented, wire format confirmed)*
- **Purpose:** Update the caller's own Merchant profile fields — proxied to Surfboard's Update Merchant Details API (`PUT`, confirmed — Surfboard's own method, not `PATCH`; the SurfPOS-facing route stays `PATCH` since that's the correct verb for a partial update from the client's perspective).
- **Auth:** Required.
- **Request:** Partial merchant object — any of `email`, `logoUrl`, `phoneNumber` (at least one required). Surfboard's Update endpoint only supports these three fields — `name`/`address`/`mccCode` are **not** updatable via this API.
- **Response (200):** `{ "merchant": {...} }` (same shape as `GET /merchant` — Surfboard's update response itself has no body to reflect, so this re-fetches the profile after a successful write).
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no `merchantId` yet), `SURFBOARD_ERROR` (502).

### `GET /merchant/status` 🔵 — *Phase 5 (implemented, wire format confirmed)*
- **Purpose:** Fetch the caller's Merchant onboarding/verification status, live. **Now backed by the real Check Application Status endpoint** (`GET /partners/:partnerId/merchants/:applicationId/status`, keyed by the caller's tracked `applicationId`) — ADR-022's original assumption that this could be derived from `GET /merchant` is disproven by the confirmed docs (Fetch Merchant Details has no status field at all).
- **Auth:** Required.
- **Response (200):** `{ "merchantId": "sb_merchant_xxx", "status": "MERCHANT_CREATED" }` — `status` is the same 9-value enum as `GET /merchant/applications/:id/status`.
- **Errors:** `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no `merchantId`/`applicationId` yet), `SURFBOARD_ERROR` (502).

### `GET /merchants/:merchantId/branding` 🔵
- **Purpose:** Fetch Surfboard checkout/receipt branding (logo, color, footer text) — see [19_SURFBOARD_WORKFLOWS.md § 5](19_SURFBOARD_WORKFLOWS.md#5-branding-workflow). Distinct from `GET /settings/:merchantId` (§ 11), which controls SurfPOS's own receipt template.
- **Auth:** Required.
- **Errors:** `FORBIDDEN`, `NOT_FOUND`, `SURFBOARD_ERROR`.

### `PATCH /merchants/:merchantId/branding` 🔵
- **Purpose:** Update Surfboard branding.
- **Auth:** Required, owner only.
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`, `SURFBOARD_ERROR`.

### `GET /stores?merchantId=` 🔵 — *originally-planned Phase 6 shape, not implemented; deferred*
- **Purpose:** List Stores for a merchant, live from Surfboard, by explicit `merchantId` query param.
- **Status:** Re-scoped to the caller-scoped `GET /stores` below (no query param, and served from a local registry rather than a live Surfboard list call — see [ADR-023](08_ARCHITECTURE_DECISIONS.md#adr-023--store-capabilities-local-registry--no-invented-list-endpoint-phase-6)).
- **Auth:** Required.
- **Response (200):** `{ "stores": [ {...} ] }`
- **Errors:** `FORBIDDEN`, `SURFBOARD_ERROR`.

### `POST /stores` 🔵🟢 — *Phase 6 (implemented)*
- **Purpose:** Create a Store for the caller's own merchant. Multi-store was never actually flag-disabled in this implementation — any number of stores per merchant is supported (see [10_TASKS.md](10_TASKS.md) task 6.3).
- **Auth:** Required.
- **Request:** `{ "name": "Blue Wave Surf Shop — Main", "address": { "line1": "...", "city": "...", "country": "SE" } }`
- **Response (201):** `{ "store": { "id", "merchantId", "name", "address", "capabilities", "status" } }`, mapped by `store.mapper.js#toDomain()`.
- **Validation:** `name` min 2 chars, `address.{line1,city,country}` required.
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no `merchantId` yet — see [ADR-022](08_ARCHITECTURE_DECISIONS.md#adr-022--merchant-functions-merchantid-resolution--repository-composition-phase-5)), `SURFBOARD_ERROR` (502).

### `GET /stores` 🔵🟢 — *Phase 6 (implemented)*
- **Purpose:** List the caller's own Stores. Served from SurfPOS's own `storeReferences/{uid}` registry (no confirmed Surfboard list-by-merchant endpoint — see [ADR-023](08_ARCHITECTURE_DECISIONS.md#adr-023--store-capabilities-local-registry--no-invented-list-endpoint-phase-6)), each entry hydrated with a live Surfboard `GET` — only Stores SurfPOS itself created will appear.
- **Auth:** Required.
- **Response (200):** `{ "stores": [ {...} ] }` (same shape as `POST /stores`'s response).
- **Errors:** `UNAUTHENTICATED` (401), `SURFBOARD_ERROR` (502).

### `GET /stores/:storeId` 🔵 — *Phase 6 (implemented)*
- **Purpose:** Fetch a single Store, live from Surfboard. `:storeId` must be one the caller's own registry lists (structurally ownership-scoped, not a live-field cross-check).
- **Auth:** Required.
- **Response (200):** `{ "store": {...} }`
- **Errors:** `UNAUTHENTICATED` (401), `NOT_FOUND` (404, unknown or not owned by caller), `SURFBOARD_ERROR` (502).

### `PATCH /stores/:storeId` 🔵 — *Phase 6 (implemented)*
- **Purpose:** Update Store fields — proxied directly to Surfboard's Store API.
- **Auth:** Required; same ownership scoping as `GET /stores/:storeId`.
- **Request:** Partial store object — `name` and/or `address` (at least one required).
- **Response (200):** `{ "store": {...} }`
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401), `NOT_FOUND` (404), `SURFBOARD_ERROR` (502).

### `GET /stores/:storeId/payment-methods` 🔵
- **Purpose:** List which payment rails this Store currently accepts — see [19_SURFBOARD_WORKFLOWS.md § 7](19_SURFBOARD_WORKFLOWS.md#7-payment-methods-workflow).
- **Auth:** Required.
- **Response (200):** `{ "methods": [ { "type": "card", "enabled": true } ] }`
- **Errors:** `FORBIDDEN`, `NOT_FOUND`, `SURFBOARD_ERROR`.

### `PATCH /stores/:storeId/payment-methods` 🔵
- **Purpose:** Enable/disable a payment rail for this Store.
- **Auth:** Required, owner only.
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`, `SURFBOARD_ERROR`.

## 4. Devices

> All endpoints proxy live to Surfboard — see [19_SURFBOARD_WORKFLOWS.md § 3](19_SURFBOARD_WORKFLOWS.md#3-device-lifecycle), [20_DOMAIN_MODEL.md § 2.3](20_DOMAIN_MODEL.md#23-device--surfboard-owned).

### `GET /stores/:storeId/devices` 🔵
- **Purpose:** List devices linked to a Store, with live status.
- **Auth:** Required.
- **Errors:** `FORBIDDEN`, `SURFBOARD_ERROR`.

### `POST /stores/:storeId/devices/link` 🔵
- **Purpose:** Link a physical card-reader device to this Store.
- **Auth:** Required, owner only.
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`, `SURFBOARD_ERROR`.

### `POST /devices/:deviceId/unlink` 🔵
- **Purpose:** Unlink a device.
- **Auth:** Required, owner only.
- **Errors:** `FORBIDDEN`, `NOT_FOUND`, `SURFBOARD_ERROR`.

## 5. Products (Catalog) 🟢 — *Phase 7 (implemented)*

Entirely Firebase-owned application data, `merchantId`-scoped (a reference to a Surfboard Merchant, resolved server-side from the caller — no request field or route param carries it). **Implemented under an `/inventory/products` prefix** rather than the bare `/products` illustrative path in earlier plans — see [ADR-024](08_ARCHITECTURE_DECISIONS.md#adr-024--inventory-management-in-memory-search--transactional-stock-phase-7).

### `POST /inventory/products`
- **Purpose:** Create a product.
- **Auth:** Required.
- **Request:** `{ "name", "sku", "unit", "costPrice", "sellingPrice", "taxRate", "barcode"?, "category"?, "supplierId"?, "imageUrl"?, "reorderLevel"? }`
- **Response (201):** `{ "product": { "id", "merchantId", "name", "sku", "barcode", "category", "unit", "costPrice", "sellingPrice", "taxRate", "supplierId", "imageUrl", "reorderLevel", "isActive", "createdAt", "updatedAt" } }`
- **Validation:** `name` min 2 chars; `sku`/`unit` required; `costPrice`/`sellingPrice` ≥ 0; `taxRate` 0–100.
- **Errors:** `VALIDATION_ERROR` (400), `UNAUTHENTICATED` (401), `NOT_FOUND` (404, no merchant reference yet).

### `GET /inventory/products?search=&category=&barcode=&includeInactive=&limit=&cursor=`
- **Purpose:** List/search/filter the caller's own merchant's product catalog, paginated.
- **Auth:** Required.
- **Response (200):** `{ "products": [ {...} ], "nextCursor": "..." | null }`
- **Notes:** `search` matches a case-insensitive substring of `name`; `barcode` is exact-match (serves barcode-scanner lookup, folding in the originally-separate task 7.3); excludes `isActive: false` products unless `includeInactive=true`; `limit` defaults to 20, max 100.

### `GET /inventory/products/:productId`
- **Purpose:** Fetch a single product. **Auth:** Required. **Errors:** `NOT_FOUND` (404).

### `PATCH /inventory/products/:productId`
- **Purpose:** Update product fields — partial, at least one required. **Auth:** Required. Same validation as create.
- **Errors:** `VALIDATION_ERROR` (400), `NOT_FOUND` (404).

### `DELETE /inventory/products/:productId`
- **Purpose:** Soft-delete — sets `isActive: false`, never removes the record. **Auth:** Required.
- **Errors:** `NOT_FOUND` (404).

## 6. Inventory (Stock) 🟢 — *Phase 7 (implemented)*

Entirely Firebase-owned, per-Store stock levels.

### `PATCH /inventory/products/:productId/stock`
- **Purpose:** Adjust stock for a product at a specific Store — transactional, never lets quantity go negative. Lazily creates the store's stock record on its first (positive-delta) adjustment.
- **Auth:** Required; `storeId` must belong to the caller (same registry check as [§ 3](#3-merchants--stores)).
- **Request:** `{ "storeId": "sb_store_xxx", "quantityDelta": -2, "reason": "damaged" }` (`reason` is logged, not persisted)
- **Response (200):** `{ "stock": { "productId", "storeId", "quantity", "reorderLevel", "lastRestockedAt", "lastUpdatedBy" } }`
- **Errors:** `VALIDATION_ERROR` (400, `quantityDelta` must be a non-zero integer), `NOT_FOUND` (404, unknown product or store not owned by caller), `INSUFFICIENT_STOCK` (422, would go negative).

## 7. Suppliers 🟢

**New section in this pass** — see [20_DOMAIN_MODEL.md § 2.16](20_DOMAIN_MODEL.md#216-supplier--firebase-owned-new-in-this-pass).

### `GET /suppliers?merchantId=&search=`
- **Purpose:** List/search a merchant's suppliers. **Auth:** Required.

### `POST /suppliers`
- **Purpose:** Create a supplier. **Auth:** Required.
- **Request:** `{ "name", "contactPhone"?, "contactEmail"?, "notes"? }`
- **Validation:** `name` required.

### `PATCH /suppliers/:supplierId`
- **Purpose:** Update supplier fields. **Auth:** Required.

## 8. AI Invoice Scanner 🟢

Full pipeline detail in [16_AI_MODULE.md](16_AI_MODULE.md). Unaffected by the Surfboard ownership change — entirely Firebase-owned.

### `POST /invoice-scans`
- **Purpose:** Upload a photographed supplier invoice for OCR + AI extraction.
- **Auth:** Required.
- **Request:** `multipart/form-data` — `image` (file), `merchantId`, `storeId`.
- **Response (201):** `{ "scanId": "...", "status": "processing" }`
- **Errors:** `VALIDATION_ERROR`, `AI_PROCESSING_ERROR`.

### `GET /invoice-scans/:scanId`
- **Purpose:** Poll scan status and extracted items. **Auth:** Required.

### `POST /invoice-scans/:scanId/confirm`
- **Purpose:** Merchant confirms extracted items → creates an `order` and updates `inventory`.
- **Auth:** Required.
- **Request:** `{ "items": [ { "productId", "qty", "unitCost" } ], "supplierId": "supplier_123" }` — `supplierId` references § 7, replacing the old free-text `supplierName`.
- **Response (201):** `{ "orderId": "..." }`
- **Errors:** `VALIDATION_ERROR`, `NOT_FOUND` (scan not found).

### `POST /invoice-scans/:scanId/reject`
- **Purpose:** Discard a scan without creating an order. **Auth:** Required.

## 9. Billing / Sales 🟢🔵

Sale creation/history is Firebase-owned; checkout internally calls the Payments integration (§ 10) but the Sale resource itself never duplicates Payment data.

### `POST /sales` 🟢🔵
- **Purpose:** Submit a cart for checkout. Backend re-validates every price/tax against live Product data (Firebase), creates the Sale, then creates a Surfboard payment intent (🔵) for the validated total.
- **Auth:** Required.
- **Request:**
  ```json
  { "storeId": "sb_store_xxx", "items": [ { "productId": "prod_123", "qty": 2 } ], "discountTotal": 0 }
  ```
- **Response (201):** `{ "saleId": "...", "grandTotal": 247.5, "status": "pending_payment", "surfboardPaymentId": "sb_payment_xxx" }`
- **Validation:** Every `productId` must exist and be active; `qty` ≤ available inventory.
- **Errors:** `INSUFFICIENT_STOCK` (422), `NOT_FOUND` (unknown product), `VALIDATION_ERROR`, `SURFBOARD_ERROR` (payment intent creation failed).

### `GET /sales?storeId=&status=&from=&to=&cursor=` 🟢
- **Purpose:** Sales history, filterable/paginated. **Auth:** Required.

### `GET /sales/:saleId` 🟢
- **Purpose:** Fetch a single sale (items, `surfboardPaymentId` reference, `receiptId` reference). **Auth:** Required.

### `POST /sales/:saleId/cancel` 🟢
- **Purpose:** Cancel a sale still in `pending_payment`. **Auth:** Required.
- **Errors:** `VALIDATION_ERROR` (422, if sale already completed).

## 10. Payments (Surfboard) 🔵

Full detail in [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md), [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle).

### `GET /payments/:paymentId` 🔵
- **Purpose:** Fetch the full, current Payment object **live from Surfboard** — this is not a Firebase read (there is no `payments` node — see [03_DATABASE_DESIGN.md § 1](03_DATABASE_DESIGN.md#1-scope-of-this-schema)).
- **Auth:** Required.
- **Errors:** `FORBIDDEN`, `NOT_FOUND`, `SURFBOARD_ERROR`.

### `PATCH /stores/:storeId/tips-config` 🔵
- **Purpose:** Enable/configure tipping (preset percentages) for a Store — see [19_SURFBOARD_WORKFLOWS.md § 6](19_SURFBOARD_WORKFLOWS.md#6-tips-workflow).
- **Auth:** Required, owner only.
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`, `SURFBOARD_ERROR`.

### `POST /webhooks/surfboard` 🔵🟢
- **Purpose:** Receives asynchronous payment (and other) status updates from Surfboard.
- **Auth:** None (Firebase auth doesn't apply) — verified via Surfboard's webhook signature header (see [15_SURFBOARD_INTEGRATION.md § 7](15_SURFBOARD_INTEGRATION.md#7-webhooks)).
- **Request:** Surfboard's webhook payload.
- **On a payment event:** updates `sales/{storeId}/{saleId}.status`/`paymentStatus` (Firebase) — never writes a duplicated Payment record.
- **Response (200):** `{ "received": true }`
- **Errors:** `401` if signature invalid.

## 11. Receipts 🟢

### `GET /receipts/:receiptId`
- **Purpose:** Fetch receipt metadata + PDF URL. **Auth:** Required.

### `POST /receipts/:receiptId/share`
- **Purpose:** Send/share the receipt to a customer contact. **Auth:** Required.
- **Request:** `{ "channel": "sms", "destination": "+46xxxxxxxxx" }`

## 12. Reports & Analytics 🟢

### `GET /analytics/:storeId?period=2026-07`
- **Purpose:** Fetch precomputed analytics rollup for a period. **Auth:** Required.

### `GET /analytics/:storeId/insights`
- **Purpose:** Fetch the latest AI-generated business insights. **Auth:** Required.
- **Response (200):** `{ "insights": [ { "title": "...", "detail": "...", "generatedAt": ... } ] }`

## 13. Settings 🟢

### `GET /settings/:merchantId`
- **Purpose:** Fetch SurfPOS's own merchant settings (tax defaults, SurfPOS receipt template, notification preferences) — **not** Surfboard branding (§ 3) or Surfboard merchant profile fields. **Auth:** Required.

### `PATCH /settings/:merchantId`
- **Purpose:** Update settings. **Auth:** Required, owner only. **Validation:** whitelisted fields only.

## 14. Health & Infra

### `GET /health`
- **Purpose:** Liveness probe for the backend process itself — independent of Firebase/Surfboard/OpenRouter connectivity.
- **Auth:** None.
- **Response (200):** `{ "success": true, "data": { "status": "ok", "uptimeSeconds": 42, "timestamp": "..." } }`

## 15. Rate Limiting & Abuse Protection

- All endpoints are rate-limited per authenticated `uid` (default: 120 requests/minute) via backend middleware.
- `POST /invoice-scans` and OpenRouter-backed endpoints have a stricter limit (default: 10/minute) due to AI provider cost.
- Surfboard-proxying endpoints (🔵, §§ 3–4, 10) should additionally respect any rate limit Surfboard itself imposes — surfaced as `SURFBOARD_ERROR` if Surfboard rejects a call for rate-limiting reasons, not a generic `INTERNAL_ERROR`.
- Exceeding SurfPOS's own limit returns `429 RATE_LIMITED`.

---

**Next:** [05_FEATURES.md](05_FEATURES.md) — feature-by-feature breakdown including UI, backend, and database touchpoints for each API above.
