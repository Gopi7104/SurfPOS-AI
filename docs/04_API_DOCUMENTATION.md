# 04 — API Documentation

> Prerequisite reading: [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md). Related: [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md), [16_AI_MODULE.md](16_AI_MODULE.md), [07_CODING_RULES.md](07_CODING_RULES.md).

---

## 1. Conventions

- **Base URL:** `https://api.surfpos.ai/api/v1` (placeholder domain — actual deployment URL is set in environment config, see [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md)).
- **Format:** JSON request/response bodies, `Content-Type: application/json`, except upload endpoints (`multipart/form-data`).
- **Authentication:** every endpoint except `POST /auth/register` and `POST /webhooks/surfboard` requires:
  ```
  Authorization: Bearer <Firebase ID Token>
  ```
  Verified server-side via Firebase Admin SDK in `auth.middleware.js`.
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
| 500 | Unhandled server error |

- **Standard error codes:** `VALIDATION_ERROR`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `INSUFFICIENT_STOCK`, `PAYMENT_FAILED`, `AI_PROCESSING_ERROR`, `RATE_LIMITED`, `INTERNAL_ERROR`.

## 2. Auth & Merchant Onboarding

### `POST /auth/register`
- **Purpose:** Complete merchant + owner-user profile creation after Firebase Auth sign-up on the client. Also triggers Surfboard merchant onboarding.
- **Auth:** None (client has just created a Firebase Auth account and passes the fresh ID token in the body for verification).
- **Request:**
  ```json
  {
    "idToken": "firebase-id-token",
    "businessName": "Blue Wave Surf Shop",
    "businessType": "retail",
    "contactPhone": "+91xxxxxxxxxx",
    "address": { "line1": "...", "city": "...", "state": "...", "pincode": "...", "country": "IN" }
  }
  ```
- **Response (201):** `{ "merchantId": "...", "storeId": "...", "surfboardOnboardingStatus": "pending" }`
- **Validation:** `businessName` required (min 2 chars), `contactPhone` required E.164 format, `idToken` must verify.
- **Errors:** `VALIDATION_ERROR` (400), `CONFLICT` (409, if this UID already owns a merchant).

### `GET /auth/me`
- **Purpose:** Fetch the authenticated user's profile + merchant + role.
- **Auth:** Required.
- **Response (200):** `{ "user": {...}, "merchant": {...}, "role": "owner" }`
- **Errors:** `NOT_FOUND` (404, profile not provisioned — client should route to onboarding).

### `POST /auth/staff-invite`
- **Purpose:** Owner invites a staff member (creates a pending staff record; staff completes sign-up client-side with the invite code).
- **Auth:** Required, `role: owner` only.
- **Request:** `{ "phone": "+91xxxxxxxxxx", "storeId": "store_1" }`
- **Response (201):** `{ "inviteCode": "..." }`
- **Errors:** `FORBIDDEN` (403, non-owner), `VALIDATION_ERROR`.

## 3. Merchants & Stores

### `GET /merchants/:merchantId`
- **Purpose:** Fetch merchant profile.
- **Auth:** Required; caller must belong to `merchantId`.
- **Response (200):** Merchant object (§4.2 of [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).
- **Errors:** `FORBIDDEN`, `NOT_FOUND`.

### `PATCH /merchants/:merchantId`
- **Purpose:** Update merchant profile fields (business name, address, contact info).
- **Auth:** Required, owner only.
- **Request:** Partial merchant object.
- **Validation:** Only whitelisted fields accepted (`businessName`, `address`, `contactPhone`, `contactEmail`).
- **Errors:** `FORBIDDEN`, `VALIDATION_ERROR`.

### `GET /stores?merchantId=`
- **Purpose:** List stores for a merchant.
- **Auth:** Required.
- **Response (200):** `{ "stores": [ {...} ] }`

### `POST /stores`
- **Purpose:** Create an additional store (future multi-store; disabled behind a flag in Phase 1 — see [10_TASKS.md](10_TASKS.md)).
- **Auth:** Required, owner only.

## 4. Products (Catalog)

### `GET /products?merchantId=&search=&barcode=&cursor=&limit=`
- **Purpose:** List/search the merchant's product catalog. `search` matches name/SKU; `barcode` is an exact-match fast path for the scanner.
- **Auth:** Required.
- **Response (200):** `{ "products": [ {...} ], "nextCursor": "..." }`

### `POST /products`
- **Purpose:** Create a product.
- **Auth:** Required, owner or staff-with-inventory-permission.
- **Request:** `{ "name", "sku", "barcode", "category", "unit", "costPrice", "sellingPrice", "taxRate", "imageUrl"? }`
- **Validation:** `name` required; `sku`/`barcode` unique per merchant; prices ≥ 0; `taxRate` 0–100.
- **Errors:** `CONFLICT` (409, duplicate SKU/barcode), `VALIDATION_ERROR`.

### `GET /products/:productId`
- **Purpose:** Fetch a single product.
- **Auth:** Required.

### `PATCH /products/:productId`
- **Purpose:** Update product fields.
- **Auth:** Required.
- **Validation:** Same as create, partial.

### `DELETE /products/:productId`
- **Purpose:** Soft-delete (`isActive: false`) — products are never hard-deleted while sales history references them.
- **Auth:** Required, owner only.

## 5. Inventory

### `GET /inventory?storeId=&lowStockOnly=`
- **Purpose:** List stock levels for a store; `lowStockOnly=true` filters to `quantity < reorderLevel`.
- **Auth:** Required.

### `PATCH /inventory/:storeId/:productId`
- **Purpose:** Manual stock adjustment (recount, damage write-off, etc.).
- **Auth:** Required.
- **Request:** `{ "quantityDelta": -2, "reason": "damaged" }`
- **Validation:** Resulting quantity cannot go below 0.
- **Errors:** `INSUFFICIENT_STOCK` (422), `VALIDATION_ERROR`.

## 6. AI Invoice Scanner

Full pipeline detail in [16_AI_MODULE.md](16_AI_MODULE.md).

### `POST /invoice-scans`
- **Purpose:** Upload a photographed supplier invoice for OCR + AI extraction.
- **Auth:** Required.
- **Request:** `multipart/form-data` — `image` (file), `merchantId`, `storeId`.
- **Response (201):** `{ "scanId": "...", "status": "processing" }` — extraction runs async.
- **Errors:** `VALIDATION_ERROR` (bad/missing image), `AI_PROCESSING_ERROR`.

### `GET /invoice-scans/:scanId`
- **Purpose:** Poll (or receive via RTDB listener) scan status and extracted items.
- **Auth:** Required.
- **Response (200):** Invoice scan object (§4.8 of [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).

### `POST /invoice-scans/:scanId/confirm`
- **Purpose:** Merchant confirms (optionally edits) extracted items → creates an `order` and updates `inventory`.
- **Auth:** Required.
- **Request:** `{ "items": [ { "productId", "qty", "unitCost" } ], "supplierName": "..." }`
- **Response (201):** `{ "orderId": "..." }`
- **Errors:** `VALIDATION_ERROR`, `NOT_FOUND` (scan not found).

### `POST /invoice-scans/:scanId/reject`
- **Purpose:** Discard a scan without creating an order.
- **Auth:** Required.

## 7. Billing / Sales

### `POST /sales`
- **Purpose:** Submit a cart for checkout. Backend re-validates every price/tax against live product data — client-submitted prices are never trusted.
- **Auth:** Required.
- **Request:**
  ```json
  {
    "storeId": "store_1",
    "items": [ { "productId": "prod_123", "qty": 2 } ],
    "discountTotal": 0
  }
  ```
- **Response (201):** `{ "saleId": "...", "grandTotal": 207.9, "status": "pending_payment", "surfboardPaymentIntentId": "sb_pi_xxx" }`
- **Validation:** Every `productId` must exist and be active; `qty` ≤ available inventory.
- **Errors:** `INSUFFICIENT_STOCK` (422), `NOT_FOUND` (unknown product), `VALIDATION_ERROR`.

### `GET /sales?storeId=&status=&from=&to=&cursor=`
- **Purpose:** Sales history, filterable/paginated.
- **Auth:** Required.

### `GET /sales/:saleId`
- **Purpose:** Fetch a single sale (with items, payment, receipt references).
- **Auth:** Required.

### `POST /sales/:saleId/cancel`
- **Purpose:** Cancel a sale still in `pending_payment`.
- **Auth:** Required.
- **Errors:** `VALIDATION_ERROR` (422, if sale already completed).

## 8. Payments (Surfboard)

Full detail in [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).

### `GET /payments/:paymentId`
- **Purpose:** Fetch payment status for a sale.
- **Auth:** Required.

### `POST /webhooks/surfboard`
- **Purpose:** Receives asynchronous payment status updates from Surfboard Payments.
- **Auth:** None (Firebase auth doesn't apply) — instead verified via Surfboard's webhook signature header (see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)).
- **Request:** Surfboard's webhook payload (shape defined by Surfboard's API).
- **Response (200):** `{ "received": true }`
- **Errors:** `401` if signature invalid.

## 9. Receipts

### `GET /receipts/:receiptId`
- **Purpose:** Fetch receipt metadata + PDF URL.
- **Auth:** Required.

### `POST /receipts/:receiptId/share`
- **Purpose:** Send/share the receipt (SMS/email/WhatsApp link) to a customer contact.
- **Auth:** Required.
- **Request:** `{ "channel": "sms", "destination": "+91xxxxxxxxxx" }`

## 10. Reports & Analytics

### `GET /analytics/:storeId?period=2026-07`
- **Purpose:** Fetch precomputed analytics rollup for a period (day or month key).
- **Auth:** Required.
- **Response (200):** Analytics object (§4.11 of [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).

### `GET /analytics/:storeId/insights`
- **Purpose:** Fetch the latest AI-generated business insights (Gemini-generated summary/recommendations).
- **Auth:** Required.
- **Response (200):** `{ "insights": [ { "title": "...", "detail": "...", "generatedAt": ... } ] }`

## 11. Settings

### `GET /settings/:merchantId`
- **Purpose:** Fetch merchant settings.
- **Auth:** Required.

### `PATCH /settings/:merchantId`
- **Purpose:** Update settings (tax defaults, receipt template, notification preferences).
- **Auth:** Required, owner only.
- **Validation:** Whitelisted fields only.

## 12. Rate Limiting & Abuse Protection

- All endpoints are rate-limited per authenticated `uid` (default: 120 requests/minute) via backend middleware.
- `POST /invoice-scans` and Gemini-backed endpoints have a stricter limit (default: 10/minute) due to AI provider cost.
- Exceeding a limit returns `429 RATE_LIMITED`.

---

**Next:** [05_FEATURES.md](05_FEATURES.md) — feature-by-feature breakdown including UI, backend, and database touchpoints for each API above.
