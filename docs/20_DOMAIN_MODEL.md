# 20 — Domain Model

> **New document, added during the Surfboard-alignment documentation pass (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md)).** This is the canonical definition of every core entity in SurfPOS AI and who owns it. Read this before [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), and [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) — those describe *how* each entity is stored/accessed; this describes *what it is* and *who is the source of truth for it*.

---

## 1. The Ownership Principle

Every entity below is owned by exactly one system of record:

- **Surfboard Payments** owns **Merchant, Store, Device, Payment, Branding, Tips, Payment Methods** — SurfPOS AI never persists a full duplicate of these in Firebase. The backend fetches them live through the [Surfboard Integration Layer](15_SURFBOARD_INTEGRATION.md) and holds only the minimal reference ID needed to partition SurfPOS's own application data (e.g. `merchantId`, `storeId` as foreign keys — never a copied `businessName`, `address`, `status`, etc.).
- **Firebase Realtime Database** owns **Inventory, Product, Sale, Order, InvoiceScan, Receipt, Analytics, Settings, Supplier, and User (app profile)** — data that only exists because SurfPOS AI exists, with no equivalent object in Surfboard's system.

See [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods) for why, and [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase) for the architectural consequence of this split.

**Rule:** if you find yourself adding a field to a Firebase record that duplicates something Surfboard already tracks (a business name, an address, a device status, a payment amount), stop — that field belongs in a live Surfboard API call, not a Firebase write. Reference the Surfboard object by ID instead.

---

## 2. Entities

### 2.1 Merchant — *Surfboard-owned*

The business entity that owns one or more Stores. Represents the retailer as a legal/business unit.

```jsonc
{
  "id": "sb_merchant_xxx",       // Surfboard-issued identifier — the only form this ID takes
  "businessName": "Blue Wave Surf Shop",
  "businessType": "retail",
  "contactEmail": "owner@example.com",
  "contactPhone": "+46...",
  "address": { "line1": "...", "city": "...", "country": "SE" },
  "status": "pending_verification | active | suspended",
  "brandingRef": "see Branding, § 2.6",
  "paymentMethodsRef": "see PaymentMethods, § 2.9"
}
```

- **Fetched via:** `integrations/surfboard/merchant.client.js` (see [15_SURFBOARD_INTEGRATION.md § 3](15_SURFBOARD_INTEGRATION.md#3-merchant-lifecycle)).
- **SurfPOS reference:** `users/{uid}.merchantId` stores this ID and nothing else about the merchant.
- **Never stored in Firebase:** `businessName`, `address`, `status`, `contactEmail/Phone` — always read live from Surfboard when a screen needs them.

### 2.2 Store — *Surfboard-owned*

A physical/logical selling location belonging to a Merchant.

```jsonc
{
  "id": "sb_store_xxx",
  "merchantId": "sb_merchant_xxx",
  "name": "Blue Wave Surf Shop — Main",
  "address": { "line1": "...", "city": "..." },
  "capabilities": { "supportedPaymentMethods": ["card", "swish"], "tipsEnabled": true },
  "status": "active | inactive"
}
```

- **Fetched via:** `integrations/surfboard/store.client.js` (see [15_SURFBOARD_INTEGRATION.md § 4](15_SURFBOARD_INTEGRATION.md#4-store-lifecycle)).
- **SurfPOS reference:** `users/{uid}.storeIds` (map of `true`) and every Firebase app-data node partitions by this ID (`inventory/{storeId}/...`, `sales/{storeId}/...`).
- **Never stored in Firebase:** `name`, `address`, `capabilities`, `status`.

### 2.3 Device — *Surfboard-owned*

A physical card-reader/terminal linked to a Store for card-present payment acceptance.

```jsonc
{
  "id": "sb_device_xxx",
  "storeId": "sb_store_xxx",
  "type": "card_reader",
  "status": "linked | unlinked | offline",
  "lastSeenAt": 1732000000000
}
```

- **Fetched/managed via:** `integrations/surfboard/device.client.js` (see [15_SURFBOARD_INTEGRATION.md § 6](15_SURFBOARD_INTEGRATION.md#6-device-lifecycle)).
- **SurfPOS reference:** a `Sale`/`Payment` may carry `surfboardDeviceId` purely as a transaction-time reference (which device took this payment) — never a full device record.

### 2.4 Payment — *Surfboard-owned*

A single payment transaction against a Sale.

```jsonc
{
  "id": "sb_payment_xxx",
  "storeId": "sb_store_xxx",
  "deviceId": "sb_device_xxx",     // nullable — phone-based rails may not use a linked device
  "amount": 207.90,
  "currency": "SEK",
  "method": "card | swish | wallet",
  "tipAmount": 0,
  "status": "created | processing | succeeded | failed | refunded"
}
```

- **Fetched/created via:** `integrations/surfboard/payment.client.js` (see [15_SURFBOARD_INTEGRATION.md § 5](15_SURFBOARD_INTEGRATION.md#5-payment-lifecycle)).
- **SurfPOS reference:** `sales/{storeId}/{saleId}.surfboardPaymentId` plus a **minimal cached status enum** (`pendingPayment | paid | failed`) used only to drive the Sale's own state machine and Firebase-side UI listeners — this is not a duplicate Payment record, it is one field capturing "what SurfPOS needs to know to react," refreshed by the Surfboard webhook (see [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle)). The authoritative amount/method/tip/status always comes from a live Surfboard call, e.g. for a "payment detail" screen.

### 2.5 Payment Methods — *Surfboard-owned*

The set of payment rails a given Store is configured to accept (card, Swish, wallet, etc.), and their per-method configuration.

```jsonc
{
  "storeId": "sb_store_xxx",
  "methods": [
    { "type": "card", "enabled": true },
    { "type": "swish", "enabled": true }
  ]
}
```

- **Fetched via:** `integrations/surfboard/store.client.js` (Payment Methods are queried/configured as a Store capability — see [15_SURFBOARD_INTEGRATION.md § 8](15_SURFBOARD_INTEGRATION.md#8-payment-methods-workflow)). No dedicated client file — folded into the Store client per [08_ARCHITECTURE_DECISIONS.md § ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split).
- **Never stored in Firebase.**

### 2.6 Branding — *Surfboard-owned*

Merchant-level receipt/checkout branding (logo, colors, footer text) as recognized by Surfboard's own checkout/receipt surfaces.

```jsonc
{
  "merchantId": "sb_merchant_xxx",
  "logoUrl": "...",
  "primaryColor": "#0A6E8C",
  "receiptFooterText": "Thank you for shopping!"
}
```

- **Fetched/updated via:** `integrations/surfboard/branding.client.js` (see [15_SURFBOARD_INTEGRATION.md § 7](15_SURFBOARD_INTEGRATION.md#7-branding-workflow)).
- **Relationship to SurfPOS's own receipt template:** SurfPOS's `settings/{merchantId}.receiptTemplate` (Firebase-owned, § 2.13) controls the SurfPOS-generated PDF receipt layout; Surfboard Branding controls Surfboard's own checkout/payment-collection surfaces. These are two different rendering surfaces that happen to both need a logo/color — they are **not** merged into one object, to keep each system authoritative for its own surface.

### 2.7 Tips — *Surfboard-owned*

Tip configuration and tip amounts collected as part of a Payment.

```jsonc
{
  "storeId": "sb_store_xxx",
  "enabled": true,
  "presetPercentages": [10, 15, 20]
}
```

- **Fetched/updated via:** `integrations/surfboard/payment.client.js` (tips are configured and collected as part of the payment flow — see [15_SURFBOARD_INTEGRATION.md § 9](15_SURFBOARD_INTEGRATION.md#9-tips-workflow)). No dedicated client file — folded into the Payment client per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split).
- **Never stored in Firebase** beyond the `tipAmount` that flows through as part of a Sale's grand total (a Firebase-owned computed value, not a duplicate of Surfboard's tip config).

### 2.8 Inventory — *Firebase-owned*

Stock level of one Product at one Store.

```jsonc
{
  "storeId": "sb_store_xxx",       // reference to a Surfboard Store
  "productId": "prod_123",
  "quantity": 42,
  "reorderLevel": 10,
  "lastRestockedAt": 1732000000000,
  "lastUpdatedBy": "fb_auth_uid"
}
```

Full schema: [03_DATABASE_DESIGN.md § 4.2](03_DATABASE_DESIGN.md#42-inventorystoreidproductid).

### 2.9 Product — *Firebase-owned*

A catalog item belonging to a Merchant, shared across that Merchant's Stores.

```jsonc
{
  "id": "prod_123",
  "merchantId": "sb_merchant_xxx",  // reference to a Surfboard Merchant
  "name": "Wax — Tropical",
  "sku": "WAX-TRP-01",
  "barcode": "8901234567890",
  "costPrice": 60,
  "sellingPrice": 99,
  "taxRate": 25,
  "isActive": true
}
```

Full schema: [03_DATABASE_DESIGN.md § 4.1](03_DATABASE_DESIGN.md#41-productsmerchantidproductid).

### 2.10 Sale — *Firebase-owned*

A POS transaction — the record that ties a cart, a Payment reference, an Inventory decrement, and a Receipt together. This is **application data** (it only exists because SurfPOS's billing flow exists), distinct from the Surfboard `Payment` it references.

```jsonc
{
  "id": "sale_789",
  "storeId": "sb_store_xxx",
  "items": [ { "productId": "prod_123", "name": "Wax — Tropical", "qty": 2, "unitPrice": 99 } ],
  "grandTotal": 207.90,
  "surfboardPaymentId": "sb_payment_xxx",
  "paymentStatus": "pending_payment | paid | failed",
  "receiptId": "rcpt_456",
  "status": "pending_payment | completed | cancelled | refunded"
}
```

Full schema: [03_DATABASE_DESIGN.md § 4.3](03_DATABASE_DESIGN.md#43-salesstoreidsaleid).

### 2.11 Order — *Firebase-owned*

A supplier purchase order — stock coming in, distinct from a Sale (stock going out). Created manually or from a confirmed AI Invoice Scan.

Full schema: [03_DATABASE_DESIGN.md § 4.4](03_DATABASE_DESIGN.md#44-ordersmerchantidorderid).

### 2.12 InvoiceScan — *Firebase-owned*

The OCR + Gemini AI extraction pipeline record. See [16_AI_MODULE.md](16_AI_MODULE.md).

Full schema: [03_DATABASE_DESIGN.md § 4.5](03_DATABASE_DESIGN.md#45-invoicescansmerchantidscanid).

### 2.13 Receipt — *Firebase-owned*

A durable, shareable record of a completed Sale (PDF + metadata), generated by SurfPOS — not to be confused with any receipt Surfboard's own checkout flow might show at the point of card capture.

Full schema: [03_DATABASE_DESIGN.md § 4.6](03_DATABASE_DESIGN.md#46-receiptsreceiptid).

### 2.14 Analytics — *Firebase-owned*

Precomputed sales/inventory rollups, feeding the Dashboard and Reports.

Full schema: [03_DATABASE_DESIGN.md § 4.7](03_DATABASE_DESIGN.md#47-analyticsstoreidperiodmetric).

### 2.15 Settings — *Firebase-owned*

App-level configuration that is genuinely SurfPOS's own concern (receipt template layout for SurfPOS-generated PDFs, notification preferences, business hours for the dashboard). **Does not** include anything Surfboard already owns — no currency, no business address, no branding colors (see § 2.6).

Full schema: [03_DATABASE_DESIGN.md § 4.9](03_DATABASE_DESIGN.md#49-settingsmerchantid).

### 2.16 Supplier — *Firebase-owned, new in this pass*

A named supplier a Merchant orders stock from. Previously an unstructured free-text field (`supplierName`) on `Order`/`InvoiceScan`; formalized as its own entity so it can be selected, reused, and (future) support supplier-specific defaults.

```jsonc
{
  "id": "supplier_123",
  "merchantId": "sb_merchant_xxx",  // reference to a Surfboard Merchant
  "name": "Coastal Distributors",
  "contactPhone": "+46...",
  "contactEmail": null,
  "notes": null,
  "createdAt": 1732000000000,
  "updatedAt": 1732000000000
}
```

Full schema: [03_DATABASE_DESIGN.md § 4.8](03_DATABASE_DESIGN.md#48-supplierssupplierid). `Order.supplierId`/`InvoiceScan.supplierId` now reference this entity instead of carrying a raw string.

### 2.17 User — *Firebase-owned (app profile) + Firebase Authentication (identity)*

The signed-in person (owner or staff). Firebase Authentication owns credentials; `users/{uid}` owns the SurfPOS-specific app profile and, critically, **only references** to the Surfboard Merchant/Stores this person belongs to.

```jsonc
{
  "uid": "fb_auth_uid",
  "email": "owner@example.com",
  "role": "owner | staff",
  "merchantId": "sb_merchant_xxx",   // reference only
  "storeIds": { "sb_store_xxx": true }, // reference only
  "status": "active | disabled"
}
```

Full schema: [03_DATABASE_DESIGN.md § 4.10](03_DATABASE_DESIGN.md#410-usersuid).

---

## 3. Relationship Map

```
Merchant  (Surfboard) (1) ──< Store        (Surfboard) (many)
Merchant  (Surfboard) (1) ──< Product      (Firebase)  (many)   [catalog is app data, scoped by merchantId reference]
Merchant  (Surfboard) (1) ──< Order        (Firebase)  (many)
Merchant  (Surfboard) (1) ──< InvoiceScan  (Firebase)  (many)
Merchant  (Surfboard) (1) ──< Supplier     (Firebase)  (many)
Merchant  (Surfboard) (1) ──1 Branding     (Surfboard)
Store     (Surfboard) (1) ──< Device       (Surfboard) (many)
Store     (Surfboard) (1) ──< Inventory    (Firebase)  (many)
Store     (Surfboard) (1) ──< Sale         (Firebase)  (many)
Store     (Surfboard) (1) ──< Analytics    (Firebase)  (many, by period)
Store     (Surfboard) (1) ──1 PaymentMethods (Surfboard)
Store     (Surfboard) (1) ──1 Tips config  (Surfboard)
Sale      (Firebase)  (1) ──> Payment      (Surfboard) (1)      [reference only, via surfboardPaymentId]
Sale      (Firebase)  (1) ──> Receipt      (Firebase)  (1)
InvoiceScan (Firebase)(1) ──> Order        (Firebase)  (0..1)
User      (Firebase)  (many) ──> Merchant  (Surfboard) (1)      [via merchantId reference]
User      (Firebase)  (many) ──> Store     (Surfboard) (many)   [via storeIds reference map]
```

No arrow above crosses from a Firebase-owned entity into full ownership of a Surfboard-owned field — every cross-system arrow is an ID reference, never a copied business object. This is the enforceable test for "did I duplicate something I shouldn't have": *can this relationship be expressed as a single ID field? If yes, that's correct. If you need more than an ID to express it, you're duplicating Surfboard data and should call the Surfboard API live instead.*

---

**Next:** [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) — how backend layers turn this domain model into working code.
