# 03 — Database Design (Firebase Realtime Database)

> Prerequisite reading: [02_ARCHITECTURE.md](02_ARCHITECTURE.md). Used by: [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), [05_FEATURES.md](05_FEATURES.md), [16_AI_MODULE.md](16_AI_MODULE.md).

---

## 1. Why Firebase Realtime Database (and not Firestore/SQL)

RTDB is a single, giant JSON tree. There are no joins, no native complex queries — every access pattern has to be designed in advance by **shaping the tree** and **denormalizing** data. This document is the contract every developer must follow so the tree stays consistent. See [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) for why RTDB was chosen over Firestore/SQL.

## 2. Core Design Rules

1. **`merchantId` is the tenant boundary.** Almost every top-level node is keyed or filtered by `merchantId`.
2. **`storeId` is the location boundary** within a merchant (Phase 1 ships with exactly one store per merchant, but the schema is multi-store-ready from day one).
3. **Flatten, don't nest deeply.** Avoid nesting collections inside collections beyond 2–3 levels — deep nesting forces clients to download data they don't need.
4. **Denormalize read-heavy data.** e.g. a sale record stores a snapshot of each item's `name` and `price` at time of sale, rather than requiring a lookup into `products` for historical accuracy and read performance.
5. **IDs are Firebase push IDs** (`push().key`) unless otherwise noted — chronologically sortable, globally unique, generated client- or server-side.
6. **Every node carries `createdAt` / `updatedAt`** (epoch milliseconds, written by the backend using server timestamps) for auditing and sorting.

## 3. Top-Level Tree

```
/
├── users/{uid}
├── merchants/{merchantId}
├── stores/{storeId}
├── products/{merchantId}/{productId}
├── inventory/{storeId}/{productId}
├── sales/{storeId}/{saleId}
├── orders/{merchantId}/{orderId}
├── invoiceScans/{merchantId}/{scanId}
├── payments/{paymentId}
├── receipts/{receiptId}
├── analytics/{storeId}/{period}/{metric}
└── settings/{merchantId}
```

## 4. Node-by-Node Design

### 4.1 `users/{uid}`

One record per authenticated person (owner or staff). `{uid}` = Firebase Auth UID.

```jsonc
{
  "uid": "fb_auth_uid",
  "email": "owner@example.com",
  "phone": "+91xxxxxxxxxx",
  "displayName": "Store Owner",
  "role": "owner",              // "owner" | "staff"
  "merchantId": "merchant_abc",
  "storeIds": { "store_1": true },
  "status": "active",            // "active" | "disabled"
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.2 `merchants/{merchantId}`

One record per registered business.

```jsonc
{
  "merchantId": "merchant_abc",
  "businessName": "Blue Wave Surf Shop",
  "ownerUid": "fb_auth_uid",
  "businessType": "retail",
  "surfboardMerchantId": "sb_merchant_xxx",  // returned by Surfboard onboarding
  "gstNumber": "GSTIN...",                    // optional, nullable
  "address": {
    "line1": "...", "city": "...", "state": "...", "pincode": "...", "country": "IN"
  },
  "contactPhone": "+91xxxxxxxxxx",
  "contactEmail": "owner@example.com",
  "subscriptionPlan": "free",
  "status": "active",             // "pending_verification" | "active" | "suspended"
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.3 `stores/{storeId}`

One record per physical location. Phase 1: one store per merchant, created automatically at registration.

```jsonc
{
  "storeId": "store_1",
  "merchantId": "merchant_abc",
  "name": "Blue Wave Surf Shop — Main",
  "address": { "line1": "...", "city": "..." },
  "timezone": "Asia/Kolkata",
  "currency": "INR",
  "staffUids": { "fb_auth_uid_2": true },
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.4 `products/{merchantId}/{productId}`

Product **catalog**, shared across all of a merchant's stores. Keyed under `merchantId` so a merchant's full catalog is one shallow read.

```jsonc
{
  "productId": "prod_123",
  "merchantId": "merchant_abc",
  "name": "Wax — Tropical",
  "sku": "WAX-TRP-01",
  "barcode": "8901234567890",
  "category": "Accessories",
  "unit": "pcs",
  "costPrice": 60,
  "sellingPrice": 99,
  "taxRate": 5,
  "imageUrl": "https://firebasestorage.../wax-tropical.jpg",
  "isActive": true,
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.5 `inventory/{storeId}/{productId}`

Stock levels **per store** (separate from the catalog so multi-store stock differs per location).

```jsonc
{
  "productId": "prod_123",
  "storeId": "store_1",
  "quantity": 42,
  "reorderLevel": 10,
  "lastRestockedAt": 1732000000000,
  "lastUpdatedBy": "fb_auth_uid"
}
```

### 4.6 `sales/{storeId}/{saleId}`

A completed (or in-progress) POS transaction. Items are a **denormalized snapshot** — do not re-look-up `products` to render sale history.

```jsonc
{
  "saleId": "sale_789",
  "storeId": "store_1",
  "merchantId": "merchant_abc",
  "cashierUid": "fb_auth_uid",
  "items": [
    { "productId": "prod_123", "name": "Wax — Tropical", "qty": 2, "unitPrice": 99, "taxRate": 5 }
  ],
  "subtotal": 198,
  "taxTotal": 9.9,
  "discountTotal": 0,
  "grandTotal": 207.9,
  "paymentId": "pay_456",
  "receiptId": "rcpt_456",
  "status": "completed",   // "pending_payment" | "completed" | "cancelled" | "refunded"
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.7 `orders/{merchantId}/{orderId}`

**Supplier purchase orders** — distinct from `sales`. Created either manually or from a confirmed AI invoice scan (§4.8). Represents stock coming *in*, not going out.

```jsonc
{
  "orderId": "order_321",
  "merchantId": "merchant_abc",
  "storeId": "store_1",
  "supplierName": "Coastal Distributors",
  "sourceInvoiceScanId": "scan_555",   // nullable — null if manually created
  "items": [
    { "productId": "prod_123", "name": "Wax — Tropical", "qty": 50, "unitCost": 60 }
  ],
  "totalCost": 3000,
  "status": "received",  // "draft" | "confirmed" | "received"
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.8 `invoiceScans/{merchantId}/{scanId}`

Result of the AI OCR + Gemini pipeline. Full flow in [16_AI_MODULE.md](16_AI_MODULE.md).

```jsonc
{
  "scanId": "scan_555",
  "merchantId": "merchant_abc",
  "storeId": "store_1",
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
  "status": "pending_review",  // "processing" | "pending_review" | "confirmed" | "rejected"
  "resultingOrderId": null,     // set once merchant confirms → order created
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.9 `payments/{paymentId}`

One record per Surfboard Payments transaction. See [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).

```jsonc
{
  "paymentId": "pay_456",
  "saleId": "sale_789",
  "merchantId": "merchant_abc",
  "storeId": "store_1",
  "amount": 207.9,
  "currency": "INR",
  "method": "card",            // "card" | "upi" | "wallet"
  "surfboardPaymentIntentId": "sb_pi_xxx",
  "surfboardDeviceId": null,     // set if a physical Surfboard device was used
  "status": "succeeded",         // "created" | "processing" | "succeeded" | "failed" | "refunded"
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

### 4.10 `receipts/{receiptId}`

```jsonc
{
  "receiptId": "rcpt_456",
  "saleId": "sale_789",
  "storeId": "store_1",
  "merchantId": "merchant_abc",
  "receiptNumber": "BWS-2026-000123",
  "pdfUrl": "https://firebasestorage.../rcpt_456.pdf",
  "customerContact": { "phone": null, "email": null },
  "createdAt": 1732000000000
}
```

### 4.11 `analytics/{storeId}/{period}/{metric}`

Precomputed rollups, written by a scheduled backend job — never computed live per-request. `{period}` examples: `2026-07-29` (daily), `2026-07` (monthly).

```jsonc
{
  "totalSales": 15400,
  "totalTransactions": 62,
  "topProducts": [ { "productId": "prod_123", "qtySold": 40, "revenue": 3960 } ],
  "lowStockCount": 3,
  "generatedAt": 1732000000000
}
```

### 4.12 `settings/{merchantId}`

```jsonc
{
  "taxSettings": { "defaultTaxRate": 5, "taxInclusivePricing": false },
  "receiptTemplate": { "footerText": "Thank you for shopping!", "showLogo": true },
  "notificationPreferences": { "lowStockAlerts": true, "dailySummaryEmail": true },
  "businessHours": { "mon": "09:00-19:00" },
  "currency": "INR",
  "locale": "en-IN",
  "updatedAt": 1732000000000
}
```

## 5. Relationships (Reference Map)

```
merchants (1) ──< stores (many)
merchants (1) ──< products (many)          [catalog shared across a merchant's stores]
stores    (1) ──< inventory (many)         [per-store stock of each product]
stores    (1) ──< sales (many)
merchants (1) ──< orders (many)
merchants (1) ──< invoiceScans (many)
invoiceScans(1)──> orders (0..1)           [confirmed scan produces one order]
sales     (1) ──> payments (1)
sales     (1) ──> receipts (1)
users     (many) ──> merchants (1)         [via merchantId]
users     (many) ──> stores (many)         [via storeIds map]
```

Because RTDB has no foreign keys or referential integrity, **all relationships above are enforced in backend service code**, not the database — see [07_CODING_RULES.md](07_CODING_RULES.md) for the rule that all writes go through backend services, never ad-hoc client writes to relational fields.

## 6. Naming Conventions

- Node/collection names: **camelCase, plural** (`products`, `invoiceScans`, `sales`).
- Field names: **camelCase** (`sellingPrice`, `createdAt`).
- IDs: **camelCase suffix `Id`** (`merchantId`, `productId`, `saleId`) and always a string (Firebase push key or backend-generated).
- Enums (`status`, `role`, `method`): **lower_snake_case or lowercase single word** — must exactly match a documented enum value; the backend validation layer is the source of truth for valid values (see [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md)).
- Timestamps: always epoch milliseconds (number), always named `createdAt` / `updatedAt` / `<verb>At` (e.g. `lastRestockedAt`).

## 7. Indexes

RTDB does not have general-purpose indexes like SQL; instead, `.indexOn` is declared per-path in `database.rules.json` for any child key used in `orderByChild()` / `equalTo()` queries. Required indexes for this schema:

| Path | Indexed field(s) | Used for |
|---|---|---|
| `products/{merchantId}` | `barcode`, `sku`, `isActive` | Barcode scan lookup, SKU search, active-only filtering |
| `inventory/{storeId}` | `quantity` | Low-stock queries (`quantity < reorderLevel` handled in backend, but ordering by quantity is indexed) |
| `sales/{storeId}` | `createdAt`, `status` | Sales history pagination, filtering by status |
| `orders/{merchantId}` | `status`, `createdAt` | Purchase order lists |
| `invoiceScans/{merchantId}` | `status`, `createdAt` | Pending-review queue |
| `payments` | `merchantId`, `saleId`, `status` | Reconciliation lookups |
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

Full rules belong in `database.rules.json` at the backend/infra level, but the principle every rule must follow:

- A user may only read/write `products/{merchantId}/*`, `inventory/{storeId}/*`, `sales/{storeId}/*`, etc. where `merchantId`/`storeId` matches a value present in their own `users/{uid}` record.
- Direct client writes to `payments`, `receipts`, and `analytics` are **disallowed** — these are backend-only writes (client reads them, never writes them).
- `invoiceScans` extraction results are backend-written; the client may only update the `status` field (to `confirmed`/`rejected`) and only on scans belonging to their own `merchantId`.

---

**Next:** [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md) — full backend API reference.
