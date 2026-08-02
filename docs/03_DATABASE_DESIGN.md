# 03 — Database Design (Firebase Realtime Database)

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase). Used by: [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), [05_FEATURES.md](05_FEATURES.md), [16_AI_MODULE.md](16_AI_MODULE.md), [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).

---

## 1. Scope of This Schema

**This file describes application data only.** Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods have **no Firebase representation** — they are owned by Surfboard and fetched live through the [Surfboard Integration Layer](15_SURFBOARD_INTEGRATION.md). Every node below uses a `merchantId`/`storeId` **purely as a foreign-key reference** to a Surfboard Merchant/Store — never as an invitation to also store that Merchant/Store's business fields. See [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle) for the rule and why it exists.

If you're looking for the old `merchants/{merchantId}`, `stores/{storeId}`, or `payments/{paymentId}` nodes: **they no longer exist.** That data is fetched live via `merchant.client.js` / `store.client.js` / `payment.client.js` (see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)) — see [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods) for why they were removed from this file.

## 2. Core Design Rules

1. **`merchantId`/`storeId` are Surfboard-issued IDs**, used here strictly as partition keys — see § 1.
2. **Flatten, don't nest deeply.** Avoid nesting collections inside collections beyond 2–3 levels.
3. **Denormalize read-heavy data.** A Sale stores a snapshot of each item's `name`/`price` at time of sale rather than requiring a lookup into `products`.
4. **IDs are Firebase push IDs** (`push().key`) for every node in this file — distinct from the Surfboard-issued `merchantId`/`storeId` reference IDs, which are opaque strings from Surfboard's namespace, not push keys.
5. **Every node carries `createdAt` / `updatedAt`** (epoch milliseconds, server timestamps).

## 3. Top-Level Tree

```
/
├── users/{uid}
├── merchantApplications/{uid}
├── products/{merchantId}/{productId}
├── inventory/{storeId}/{productId}
├── sales/{storeId}/{saleId}
├── orders/{merchantId}/{orderId}
├── invoiceScans/{merchantId}/{scanId}
├── suppliers/{merchantId}/{supplierId}
├── receipts/{receiptId}
├── analytics/{storeId}/{period}/{metric}
└── settings/{merchantId}
```

## 4. Node-by-Node Design

### 4.1 `products/{merchantId}/{productId}`

Product catalog, shared across all of a merchant's Surfboard Stores. `merchantId` is a reference to a Surfboard Merchant. Implemented in Phase 7 (docs/08_ARCHITECTURE_DECISIONS.md § ADR-024) — the record's own id field is `id` (matching [20_DOMAIN_MODEL.md § 2.9](20_DOMAIN_MODEL.md#29-product--firebase-owned) and every other domain entity's shape in this codebase), correcting this section's earlier `productId` naming, which predated any implementation and never matched the domain model doc. `supplierId` and `reorderLevel` (= "Minimum Stock") are new fields added in Phase 7.

```jsonc
{
  "id": "prod_123",
  "merchantId": "sb_merchant_xxx",
  "name": "Wax — Tropical",
  "sku": "WAX-TRP-01",
  "barcode": "8901234567890",
  "category": "Accessories",
  "unit": "pcs",
  "costPrice": 60,
  "sellingPrice": 99,
  "taxRate": 25,
  "supplierId": null,
  "reorderLevel": 10,
  "imageUrl": "https://firebasestorage.../wax-tropical.jpg",
  "isActive": true,
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

- `supplierId` — nullable reference to the already-documented but not-yet-built Supplier entity ([§ 4.6](#46-suppliersmerchantidsupplierid)/[20_DOMAIN_MODEL.md § 2.16](20_DOMAIN_MODEL.md#216-supplier--firebase-owned-new-in-this-pass)); Supplier CRUD itself is task 7.4, not implemented this pass.
- `reorderLevel` — the "Minimum Stock" facet requested for Phase 7; kept this existing field name (not renamed to `minimumStock`) for continuity with [§ 4.2](#42-inventorystoreidproductid) below, which already used it.

### 4.2 `inventory/{storeId}/{productId}`

Stock levels per Store. `storeId` is a reference to a Surfboard Store.

```jsonc
{
  "productId": "prod_123",
  "storeId": "sb_store_xxx",
  "quantity": 42,
  "reorderLevel": 10,
  "lastRestockedAt": 1732000000000,
  "lastUpdatedBy": "fb_auth_uid"
}
```

### 4.3 `sales/{storeId}/{saleId}`

A completed (or in-progress) POS transaction — SurfPOS application data, distinct from the Surfboard Payment it references (see [20_DOMAIN_MODEL.md § 2.10](20_DOMAIN_MODEL.md#210-sale--firebase-owned)).

```jsonc
{
  "saleId": "sale_789",
  "storeId": "sb_store_xxx",
  "merchantId": "sb_merchant_xxx",
  "cashierUid": "fb_auth_uid",
  "items": [
    { "productId": "prod_123", "name": "Wax — Tropical", "qty": 2, "unitPrice": 99, "taxRate": 25 }
  ],
  "subtotal": 198,
  "taxTotal": 49.5,
  "discountTotal": 0,
  "grandTotal": 247.5,
  "surfboardPaymentId": "sb_payment_xxx",
  "paymentStatus": "pending_payment",
  "receiptId": "rcpt_456",
  "status": "pending_payment",
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

- `surfboardPaymentId` + `paymentStatus` are a **reference and a minimal cached status enum only** — never the full Payment object (amount/method/tip live in Surfboard, fetched live via `payment.client.js` when a screen needs the full detail). See [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle).
- `status` (`pending_payment | completed | cancelled | refunded`) is the Sale's own state machine, updated by the verified Surfboard webhook — see [15_SURFBOARD_INTEGRATION.md § 7](15_SURFBOARD_INTEGRATION.md#7-webhooks).

### 4.4 `orders/{merchantId}/{orderId}`

Supplier purchase orders — stock coming *in*, distinct from `sales` (stock going *out*). Created manually or from a confirmed AI invoice scan.

```jsonc
{
  "orderId": "order_321",
  "merchantId": "sb_merchant_xxx",
  "storeId": "sb_store_xxx",
  "supplierId": "supplier_123",
  "sourceInvoiceScanId": "scan_555",
  "items": [
    { "productId": "prod_123", "name": "Wax — Tropical", "qty": 50, "unitCost": 60 }
  ],
  "totalCost": 3000,
  "status": "draft",
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

`supplierId` references `suppliers/{merchantId}/{supplierId}` (§ 4.6) — no more free-text supplier name on this node.

### 4.5 `invoiceScans/{merchantId}/{scanId}`

Result of the AI OCR + OpenRouter pipeline. Full flow in [16_AI_MODULE.md](16_AI_MODULE.md).

```jsonc
{
  "scanId": "scan_555",
  "merchantId": "sb_merchant_xxx",
  "storeId": "sb_store_xxx",
  "imageUrl": "https://firebasestorage.../invoice_scan_555.jpg",
  "ocrRawText": "...",
  "extractedItems": [
    {
      "rawName": "Trop Wax 50pk",
      "qty": 50,
      "unitPrice": 60,
      "matchedProductId": "prod_123",
      "matchConfidence": 0.92
    }
  ],
  "supplierNameGuess": "Coastal Distributors",
  "matchedSupplierId": null,
  "status": "pending_review",
  "resultingOrderId": null,
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

`supplierNameGuess` is the raw AI-extracted text; `matchedSupplierId` is set once the merchant confirms/picks a `suppliers/{merchantId}/{supplierId}` record during review (or the backend creates a new one) — see [05_FEATURES.md § 6](05_FEATURES.md#6-ai-invoice-scanner).

### 4.6 `suppliers/{merchantId}/{supplierId}`

**New node in this pass** — formalizes what was previously a free-text `supplierName` string on `orders`/`invoiceScans`. See [20_DOMAIN_MODEL.md § 2.16](20_DOMAIN_MODEL.md#216-supplier--firebase-owned-new-in-this-pass).

```jsonc
{
  "supplierId": "supplier_123",
  "merchantId": "sb_merchant_xxx",
  "name": "Coastal Distributors",
  "contactPhone": "+46...",
  "contactEmail": null,
  "notes": null,
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.7 `receipts/{receiptId}`

```jsonc
{
  "receiptId": "rcpt_456",
  "saleId": "sale_789",
  "storeId": "sb_store_xxx",
  "merchantId": "sb_merchant_xxx",
  "receiptNumber": "BWS-2026-000123",
  "pdfUrl": "https://firebasestorage.../rcpt_456.pdf",
  "surfboardPaymentId": "sb_payment_xxx",
  "customerContact": { "phone": null, "email": null },
  "createdAt": 1732000000000
}
```

`surfboardPaymentId` replaces the old `paymentId` field (which pointed at a Firebase `payments/{paymentId}` node that no longer exists) — a reference only, per § 1.

### 4.8 `analytics/{storeId}/{period}/{metric}`

Precomputed rollups, written by a scheduled backend job — never computed live per-request.

```jsonc
{
  "totalSales": 15400,
  "totalTransactions": 62,
  "topProducts": [ { "productId": "prod_123", "qtySold": 40, "revenue": 3960 } ],
  "lowStockCount": 3,
  "generatedAt": 1732000000000
}
```

### 4.9 `settings/{merchantId}`

App-level configuration that is genuinely SurfPOS's own concern — deliberately **excludes** anything Surfboard already owns (no currency, no business address, no branding colors — see [20_DOMAIN_MODEL.md § 2.15](20_DOMAIN_MODEL.md#215-settings--firebase-owned)).

```jsonc
{
  "taxSettings": { "defaultTaxRate": 25, "taxInclusivePricing": false },
  "receiptTemplate": { "footerText": "Thank you for shopping!", "showLogo": true },
  "notificationPreferences": { "lowStockAlerts": true, "dailySummaryEmail": true },
  "businessHours": { "mon": "09:00-19:00" },
  "locale": "sv-SE",
  "updatedAt": 1732000000000
}
```

`receiptTemplate` here controls SurfPOS's own generated PDF receipts (§ 4.7) — it is a separate concept from Surfboard's Branding (checkout/payment-surface branding), which is never cached in Firebase; see [19_SURFBOARD_WORKFLOWS.md § 5](19_SURFBOARD_WORKFLOWS.md#5-branding-workflow).

### 4.10 `users/{uid}`

One record per authenticated person (owner or staff). `{uid}` = Firebase Auth UID. Identity itself lives in Firebase Authentication; this node is SurfPOS's app profile, holding **only references** to the Surfboard Merchant/Stores this person belongs to.

```jsonc
{
  "uid": "fb_auth_uid",
  "email": "owner@example.com",
  "phone": "+46...",
  "displayName": "Store Owner",
  "role": "owner",
  "merchantId": "sb_merchant_xxx",
  "storeIds": { "sb_store_xxx": true },
  "status": "active",
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.11 `merchantApplications/{uid}`

Tracks a submitted Surfboard Merchant Creation request — new in Phase 4 (see [08_ARCHITECTURE_DECISIONS.md § ADR-021](08_ARCHITECTURE_DECISIONS.md#adr-021--merchant-application-tracking-entity-phase-4)). One record per submitting user (`{uid}` = Firebase Auth UID, same key as `users/{uid}`); **not** a duplicate of the Merchant object — see [20_DOMAIN_MODEL.md § 2.18](20_DOMAIN_MODEL.md#218-merchantapplication--firebase-owned-new-in-phase-4).

```jsonc
{
  "applicationId": "uid_or_surfboard_application_id",
  "merchantId": "sb_merchant_xxx",
  "applicationStatus": "pending_verification",
  "applicationUrl": "https://onboard.surfboardpayments.com/...",
  "submittedAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

- `merchantId`/`applicationUrl` are `null` until Surfboard's response provides them (async KYC onboarding).
- `applicationId` defaults to `{uid}` when Surfboard's response doesn't supply a distinct application identifier (still-unconfirmed field, see [ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made)) — this keeps a `GET` lookup by id a simple, ownership-scoped read of the caller's own `{uid}` record rather than needing a second index.
- This record does **not** get linked onto `users/{uid}.merchantId` yet — that write is still open work (see [10_TASKS.md](10_TASKS.md) Phase 4 note).

## 5. Relationships (Reference Map)

```
Merchant  (Surfboard) (1) ──< Store        (Surfboard) (many)
Merchant  (Surfboard) (1) ──< products     (Firebase)  (many)   [via merchantId reference]
Merchant  (Surfboard) (1) ──< orders       (Firebase)  (many)
Merchant  (Surfboard) (1) ──< invoiceScans (Firebase)  (many)
Merchant  (Surfboard) (1) ──< suppliers    (Firebase)  (many)
Store     (Surfboard) (1) ──< inventory    (Firebase)  (many)
Store     (Surfboard) (1) ──< sales        (Firebase)  (many)
Store     (Surfboard) (1) ──< analytics    (Firebase)  (many)
sales     (Firebase)  (1) ──> Payment      (Surfboard) (1)      [reference only]
sales     (Firebase)  (1) ──> receipts     (Firebase)  (1)
invoiceScans(Firebase) (1) ──> orders      (Firebase)  (0..1)
users     (Firebase)  (many) ──> Merchant  (Surfboard) (1)      [via merchantId reference]
users     (Firebase)  (many) ──> Store     (Surfboard) (many)   [via storeIds reference map]
users     (Firebase)  (1) ──1 merchantApplications (Firebase)   [same {uid} key]
merchantApplications (Firebase) (1) ──> Merchant (Surfboard) (0..1) [reference only, once assigned]
```

Full entity definitions: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md). Because RTDB has no foreign keys, **every relationship above is enforced in backend Repository/Service code**, not the database — see [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).

## 6. Naming Conventions

- Node/collection names: **camelCase, plural** (`products`, `invoiceScans`, `sales`, `suppliers`).
- Field names: **camelCase** (`sellingPrice`, `createdAt`).
- IDs: **camelCase suffix `Id`**, always a string. `merchantId`/`storeId` are Surfboard-issued opaque strings (foreign keys); every other `*Id` is a Firebase push key.
- Enums (`status`, `role`): **lower_snake_case or lowercase single word** — the backend validation layer is the source of truth for valid values (see [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md)).
- Timestamps: always epoch milliseconds, always named `createdAt` / `updatedAt` / `<verb>At`.

## 7. Indexes

| Path | Indexed field(s) | Used for |
|---|---|---|
| `products/{merchantId}` | `barcode`, `sku`, `isActive` | Barcode scan lookup, SKU search, active-only filtering |
| `inventory/{storeId}` | `quantity` | Low-stock queries |
| `sales/{storeId}` | `createdAt`, `status` | Sales history pagination, filtering by status |
| `orders/{merchantId}` | `status`, `createdAt` | Purchase order lists |
| `invoiceScans/{merchantId}` | `status`, `createdAt` | Pending-review queue |
| `suppliers/{merchantId}` | `name` | Supplier search/autocomplete |
| `users` | `merchantId` | Staff list per merchant |

Example `database.rules.json` fragment:

```json
{
  "rules": {
    "products": {
      "$merchantId": {
        ".indexOn": ["barcode", "sku", "isActive"]
      }
    },
    "sales": {
      "$storeId": {
        ".indexOn": ["createdAt", "status"]
      }
    }
  }
}
```

## 8. Security Rules (Summary)

Full rules belong in `database.rules.json`, but the principle every rule must follow:

- A user may only read/write `products/{merchantId}/*`, `inventory/{storeId}/*`, `sales/{storeId}/*`, `orders/{merchantId}/*`, `invoiceScans/{merchantId}/*`, `suppliers/{merchantId}/*` where `merchantId`/`storeId` matches a value present in their own `users/{uid}` record.
- Direct client writes to `receipts` and `analytics` are **disallowed** — backend-only writes.
- `invoiceScans` extraction results are backend-written; the client may only update the `status` field (`confirmed`/`rejected`) and only on scans belonging to their own `merchantId`.
- **There are no rules for `merchants`, `stores`, `devices`, `payments`, `branding`, `tips`, or `paymentMethods` — those paths do not exist in this database.** Access control for those entities is enforced entirely by the backend's Surfboard Integration Layer and Surfboard's own API-level authorization, not Firebase Security Rules.

---

**Next:** [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md) — full backend API reference.
