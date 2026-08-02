# 05 — Features

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md). Each feature below cross-references the exact endpoints and data-ownership it touches.

---

## 1. Merchant Registration

**Purpose:** Let a new small-retail owner self-serve onto SurfPOS AI, creating their Merchant and default Store **in Surfboard** — not as a separate SurfPOS-owned record.

**Workflow:**
1. User downloads the app, chooses "Create Business Account."
2. User signs up via Firebase Authentication (email/password or phone OTP).
3. App collects business details (name, type, address, contact) in a short multi-step form.
4. App calls `POST /auth/register` with the fresh ID token + business details.
5. Backend creates the Merchant + default Store in Surfboard (see [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle)), then writes only `users/{uid}.merchantId`/`storeIds` references in Firebase.
6. App lands on the Dashboard once the references are provisioned (even if Surfboard's own onboarding/KYC is still `pending_verification`).

**UI:** Multi-step onboarding wizard (business name → type → address → contact → review). Cannot be skipped.

**Backend:** `POST /auth/register` (see [04_API_DOCUMENTATION.md § 2](04_API_DOCUMENTATION.md#2-auth--merchant-onboarding)). Orchestrates: Firebase Admin token verification → Surfboard Merchant + Store creation → Firebase reference write.

**Database:** Writes only `users/{uid}` (see [03_DATABASE_DESIGN.md § 4.10](03_DATABASE_DESIGN.md#410-usersuid)). No `merchants`/`stores` node exists to write to.

**Future Improvements:** Document/KYC upload during onboarding; business-category-specific default catalog templates; invite-based team onboarding during registration itself.

---

## 2. Authentication

**Purpose:** Secure, low-friction identity for owners and staff, with role-based access. Identity is a Firebase concern regardless of the Surfboard ownership change — this feature is otherwise unaffected.

**Workflow:**
1. Owner or staff signs in via Firebase Auth.
2. Flutter app receives a Firebase ID token, attaches it to every backend call via the `ApiClient` interceptor.
3. On first launch after login, app calls `GET /auth/me` to resolve `merchantId`/`storeIds` **references** and `role`, and route accordingly.
4. Staff accounts are created via `POST /auth/staff-invite` (owner-only).

**UI:** Standard sign-in/sign-up screens; "Forgot password" via Firebase Auth's built-in reset flow; role indicator in app header/drawer.

**Backend:** `auth.middleware.js` verifies the Bearer token on every protected route. `GET /auth/me`, `POST /auth/staff-invite` (see [04_API_DOCUMENTATION.md § 2](04_API_DOCUMENTATION.md#2-auth--merchant-onboarding)).

**Database:** `users/{uid}` (role, `merchantId`/`storeIds` references). Firebase Auth stores credentials — SurfPOS never stores passwords, and never stores Merchant/Store business data here either.

**Future Improvements:** Granular staff permissions, biometric app-lock, session device management.

---

## 3. Dashboard

**Purpose:** Give the owner/staff an at-a-glance daily snapshot. Entirely Firebase-owned application data — unaffected by the Surfboard ownership change.

**Workflow:**
1. On load, app calls `GET /analytics/:storeId` and `GET /analytics/:storeId/insights`.
2. Displays: today's sales total, transaction count, top-selling products, low-stock alert count, and AI-generated insights.
3. Tapping any card deep-links into the relevant feature.

**UI:** Scrollable single-screen card layout (see [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md)); pull-to-refresh; skeleton loaders.

**Backend:** `GET /analytics/:storeId`, `GET /analytics/:storeId/insights` (see [04_API_DOCUMENTATION.md § 12](04_API_DOCUMENTATION.md#12-reports--analytics)).

**Database:** Reads `analytics/{storeId}/{period}` (see [03_DATABASE_DESIGN.md § 4.8](03_DATABASE_DESIGN.md#48-analyticsstoreidperiodmetric)).

**Future Improvements:** Customizable dashboard widgets, multi-store aggregate view, comparison-to-last-period deltas.

---

## 4. Inventory Management

**Purpose:** Give the merchant an always-accurate view of stock per Store. Entirely Firebase-owned; unaffected by the Surfboard ownership change beyond `storeId` now being a Surfboard reference rather than a locally-generated ID.

**Workflow:**
1. Owner/staff opens Inventory tab → list of products with current quantity, sorted by low-stock-first.
2. Manual adjustments go through `PATCH /inventory/:storeId/:productId` with a signed delta + reason.
3. Stock also changes automatically from a completed **Sale** (decrement) and a confirmed **AI Invoice Scan / Purchase Order** (increment) — always through the same `inventory.service.js`, never ad hoc.
4. Reorder-level breaches surface as a Dashboard alert.

**UI:** Filterable/searchable list, quantity badges color-coded by stock health, manual-adjustment bottom sheet.

**Backend:** `GET /inventory`, `PATCH /inventory/:storeId/:productId` (see [04_API_DOCUMENTATION.md § 6](04_API_DOCUMENTATION.md#6-inventory)). Shared `inventory.service.js`/`inventory.repository.js` per [21_BACKEND_GUIDELINES.md § 8](21_BACKEND_GUIDELINES.md#8-cross-module-rule).

**Database:** `inventory/{storeId}/{productId}` (see [03_DATABASE_DESIGN.md § 4.2](03_DATABASE_DESIGN.md#42-inventorystoreidproductid)).

**Future Improvements:** Batch/lot tracking, expiry-date tracking, multi-store stock transfer.

---

## 5. Barcode Scanner

**Purpose:** Let the phone camera act as the barcode scanner. Unaffected by the Surfboard ownership change.

**Workflow:**
1. User taps the scan icon (from Billing or Inventory).
2. Camera opens with a live barcode-detection overlay (on-device).
3. On decode, app looks up the barcode against the locally cached catalog, falling back to `GET /products?barcode=`.
4. Matched product is added to the active cart or opened for stock adjustment.
5. If no match, user is prompted to create a new product.

**UI:** Full-screen camera view, haptic + sound feedback, manual barcode text-entry fallback.

**Backend:** `GET /products?barcode=` (see [04_API_DOCUMENTATION.md § 5](04_API_DOCUMENTATION.md#5-products-catalog)).

**Database:** Reads `products/{merchantId}` filtered by `barcode` (indexed — see [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes)).

**Future Improvements:** Bluetooth barcode-gun support, batch-scan mode.

---

## 6. AI Invoice Scanner

**Purpose:** Eliminate manual re-typing of supplier invoices. Full pipeline detail: [16_AI_MODULE.md](16_AI_MODULE.md). Entirely Firebase-owned; the only change in this pass is that suppliers are now a structured entity.

**Workflow:**
1. User photographs a supplier invoice.
2. App uploads via `POST /invoice-scans` → backend stores it in Firebase Storage, kicks off async processing.
3. Backend runs OCR → raw text → OpenRouter structuring → `{name, qty, unitPrice}` line items.
4. Backend fuzzy-matches each item against `products`, attaching `matchConfidence`.
5. Scan status flips to `pending_review`; app shows a review screen: each line item, matched product, quantity, cost, and a supplier picker (matched against `suppliers/{merchantId}` — see [03_DATABASE_DESIGN.md § 4.6](03_DATABASE_DESIGN.md#46-supplierssmerchantidsupplierid), creating a new Supplier record if none matches).
6. Merchant confirms → `POST /invoice-scans/:scanId/confirm` (now includes `supplierId`, see [04_API_DOCUMENTATION.md § 8](04_API_DOCUMENTATION.md#8-ai-invoice-scanner)) → backend creates an `order` and increments `inventory`.
7. Merchant can instead **Reject** the scan.

**UI:** Camera capture → processing spinner → review screen with per-line confidence indicators and a supplier picker/creator.

**Backend:** `POST /invoice-scans`, `GET /invoice-scans/:scanId`, `POST /invoice-scans/:scanId/confirm`, `POST /invoice-scans/:scanId/reject`. AI orchestration in `modules/ai/`.

**Database:** Writes `invoiceScans/{merchantId}/{scanId}`; on confirm, writes `orders/{merchantId}/{orderId}` (with `supplierId`), updates `inventory`, and may create a `suppliers/{merchantId}/{supplierId}` record.

**Future Improvements:** Multi-page invoice support, supplier auto-recognition across repeated scans, auto-confirm above a very high confidence threshold, direct supplier e-invoice ingestion.

---

## 7. Billing

**Purpose:** The core checkout workflow. Firebase-owned Sale creation, handed off to Surfboard for payment execution.

**Workflow:**
1. Cashier builds a cart (see **Cart** below).
2. Taps **Checkout** → app calls `POST /sales` with cart contents.
3. Backend re-validates every item's price/tax against live `products` data, creates the Sale (`status: pending_payment`), then creates a Surfboard payment intent for the validated total (see [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle)).
4. App presents the Surfboard payment collection UI/flow for that intent.
5. On payment confirmation (via Surfboard webhook), the Sale flips to `completed`, inventory decrements, and a receipt is generated.
6. App transitions to the receipt/confirmation screen (exact real-time mechanism is an open item — see [02_ARCHITECTURE.md § 2](02_ARCHITECTURE.md#2-frontend-flutter)).

**UI:** Checkout summary → payment method/collection screen → success/failure screen with receipt share options.

**Backend:** `POST /sales`, `POST /sales/:saleId/cancel` (see [04_API_DOCUMENTATION.md § 9](04_API_DOCUMENTATION.md#9-billing--sales)); payment orchestration per [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).

**Database:** Writes `sales/{storeId}/{saleId}` (with `surfboardPaymentId` reference), `receipts/{receiptId}`; updates `inventory/{storeId}/{productId}`. **No `payments/{paymentId}` Firebase write** — see [03_DATABASE_DESIGN.md § 4.3](03_DATABASE_DESIGN.md#43-salesstoreidsaleid).

**Future Improvements:** Split payments, held/parked sales, offline sale queueing.

---

## 8. Cart

**Purpose:** Local, in-progress collection of items before checkout. Unaffected by the Surfboard ownership change.

**Workflow:**
1. Items added via barcode scan or search.
2. Cart is purely **client-side local state** until checkout.
3. Quantity adjustable, item removable inline.
4. Discounts (if enabled) applied at cart level before checkout.
5. Cart clears on successful checkout or explicit "clear cart."

**UI:** Persistent cart summary bar; full cart screen with line-item list, quantity steppers, swipe-to-remove.

**Backend/Database:** None directly — touches the backend only at checkout (`POST /sales`).

**Future Improvements:** Persist an in-progress cart locally; "held sales" that sync to the backend.

---

## 9. Payments

**Purpose:** Accept payment for a Sale through Surfboard, keeping the Sale's own status in sync via webhook — without SurfPOS ever owning a duplicate Payment record.

**Workflow:** Full detail: [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle). Summary: backend creates a Surfboard payment intent for a validated Sale total → client collects payment via Surfboard's device/SDK/QR flow → Surfboard webhook confirms → backend updates the Sale's `status`/`paymentStatus` only.

**UI:** Payment-method selection (driven by live Store Payment Methods, see § 13), in-progress spinner, clear success/failure state, retry option without re-building the cart.

**Backend:** `GET /payments/:paymentId` (live Surfboard proxy), `POST /webhooks/surfboard`, `PATCH /stores/:storeId/tips-config` (see [04_API_DOCUMENTATION.md § 10](04_API_DOCUMENTATION.md#10-payments-surfboard)).

**Database:** No Firebase Payment record — `sales/{storeId}/{saleId}.surfboardPaymentId` + `paymentStatus` only (see [03_DATABASE_DESIGN.md § 4.3](03_DATABASE_DESIGN.md#43-salesstoreidsaleid)).

**Future Improvements:** Refunds/partial refunds, saved customer payment methods, multi-device payment collection.

---

## 10. Receipt

**Purpose:** Give every Sale a durable, shareable digital record — SurfPOS's own concern, distinct from anything Surfboard's checkout surface shows.

**Workflow:**
1. On sale completion, backend generates a receipt PDF (from SurfPOS's own configurable template, see § 12), uploads it to Firebase Storage, writes the `receipts` record referencing `surfboardPaymentId`.
2. App shows the receipt immediately and offers share options.

**UI:** Receipt preview screen; share sheet; access to past receipts from Sales/Reports history.

**Backend:** `GET /receipts/:receiptId`, `POST /receipts/:receiptId/share` (see [04_API_DOCUMENTATION.md § 11](04_API_DOCUMENTATION.md#11-receipts)).

**Database:** `receipts/{receiptId}` + PDF in Firebase Storage (see [03_DATABASE_DESIGN.md § 4.7](03_DATABASE_DESIGN.md#47-receiptsreceiptid)).

**Future Improvements:** Bluetooth thermal printer support, itemized tax-invoice format, customer-facing receipt lookup portal.

---

## 11. Reports

**Purpose:** Let the merchant look back at sales/inventory history. Unaffected by the Surfboard ownership change.

**Workflow:**
1. Merchant opens Reports, picks a date range and dimension.
2. App queries `GET /sales` (paginated) and/or `GET /analytics/:storeId?period=`.
3. Reports can be exported (future) or viewed in-app.

**UI:** Date-range picker, tabbed report types, simple charts.

**Backend:** `GET /sales`, `GET /analytics/:storeId`.

**Database:** Reads `sales/{storeId}` and `analytics/{storeId}/{period}`.

**Future Improvements:** CSV/PDF export, scheduled email reports, custom report builder.

---

## 12. Analytics & AI Business Insights

**Purpose:** Turn raw sales data into decisions the merchant can act on. Unaffected by the Surfboard ownership change.

**Workflow:**
1. A scheduled backend job aggregates raw `sales` into `analytics/{storeId}/{period}` rollups.
2. Periodically, the backend sends recent aggregates to OpenRouter for insight generation (see [16_AI_MODULE.md](16_AI_MODULE.md)).
3. Insights surface on the Dashboard and in Reports.

**UI:** Insight cards with icon/severity, tap-through to the relevant product/report.

**Backend:** `GET /analytics/:storeId/insights`; generation job in `modules/ai/`.

**Database:** Reads/writes `analytics/{storeId}/{period}`.

**Future Improvements:** Predictive restocking, anomaly detection, natural-language "ask your data" interface.

---

## 13. Settings

**Purpose:** SurfPOS's own configuration — tax defaults, SurfPOS receipt template, notifications, staff. **Deliberately excludes** anything Surfboard owns (currency, business address, checkout branding — see § 15).

**Workflow:**
1. Owner opens Settings → sections for Tax, SurfPOS Receipt Template, Notifications, Staff Management.
2. Each section reads/writes via `GET/PATCH /settings/:merchantId`.
3. Merchant-profile fields (business name/address) and Branding now live under their own Surfboard-proxying sections (§§ 14–15), not here.

**UI:** Standard settings list → detail screens per section; staff list with invite/remove actions.

**Backend:** `GET/PATCH /settings/:merchantId`, plus `POST /auth/staff-invite` (see [04_API_DOCUMENTATION.md §§ 2, 13](04_API_DOCUMENTATION.md#13-settings)).

**Database:** `settings/{merchantId}`, `users/{uid}` (see [03_DATABASE_DESIGN.md § 4.9](03_DATABASE_DESIGN.md#49-settingsmerchantid)).

**Future Improvements:** Per-store settings overrides, configurable role permissions, data export/account deletion self-service.

---

## 14. Store Capabilities & Payment Methods

**New feature section in this pass** — see [19_SURFBOARD_WORKFLOWS.md §§ 2, 7](19_SURFBOARD_WORKFLOWS.md#2-store-lifecycle).

**Purpose:** Let the merchant see/configure which payment rails a Store accepts, live from Surfboard.

**Workflow:**
1. Owner opens Settings → Store Capabilities.
2. App calls `GET /stores/:storeId/payment-methods`.
3. Owner toggles a rail on/off → `PATCH /stores/:storeId/payment-methods`.
4. Checkout (§ 9) reads this live to decide which payment-collection UI to present.

**Backend:** `GET/PATCH /stores/:storeId/payment-methods` (see [04_API_DOCUMENTATION.md § 3](04_API_DOCUMENTATION.md#3-merchants--stores)).

**Database:** None — always live from Surfboard.

---

## 15. Device Management

**New feature section in this pass** — see [19_SURFBOARD_WORKFLOWS.md § 3](19_SURFBOARD_WORKFLOWS.md#3-device-lifecycle).

**Purpose:** Link/unlink Surfboard card-reader devices to a Store and check their live status.

**Workflow:**
1. Owner opens Settings → Devices → "Link a device."
2. App calls `POST /stores/:storeId/devices/link`.
3. Device list shows live status (linked/unlinked/offline) via `GET /stores/:storeId/devices`.
4. Unlinking calls `POST /devices/:deviceId/unlink`.

**Backend:** `GET /stores/:storeId/devices`, `POST /stores/:storeId/devices/link`, `POST /devices/:deviceId/unlink` (see [04_API_DOCUMENTATION.md § 4](04_API_DOCUMENTATION.md#4-devices)).

**Database:** None — always live from Surfboard.

---

## 16. Branding

**New feature section in this pass** — see [19_SURFBOARD_WORKFLOWS.md § 5](19_SURFBOARD_WORKFLOWS.md#5-branding-workflow).

**Purpose:** Configure the logo/color/footer text Surfboard's own checkout and payment-collection surfaces show — distinct from SurfPOS's own receipt template (§ 13).

**Workflow:**
1. Owner opens Settings → Branding.
2. App calls `GET /merchants/:merchantId/branding`, edits, calls `PATCH /merchants/:merchantId/branding`.

**Backend:** `GET/PATCH /merchants/:merchantId/branding` (see [04_API_DOCUMENTATION.md § 3](04_API_DOCUMENTATION.md#3-merchants--stores)).

**Database:** None — always live from Surfboard.

---

**Next:** [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md) — visual design system referenced throughout this document.
