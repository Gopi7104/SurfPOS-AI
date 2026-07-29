# 05 — Features

> Prerequisite reading: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md). Each feature below cross-references the exact endpoints and DB nodes it touches — this is the single most detailed functional reference in the docs set.

---

## 1. Merchant Registration

**Purpose:** Let a new small-retail owner self-serve onto SurfPOS AI without any manual approval step, and kick off Surfboard Payments onboarding in the background.

**Workflow:**
1. User downloads the app, chooses "Create Business Account."
2. User signs up via Firebase Authentication (email/password or phone OTP).
3. App collects business details (name, type, address, contact) in a short multi-step form.
4. App calls `POST /auth/register` with the fresh ID token + business details.
5. Backend creates `merchants/{merchantId}`, `stores/{storeId}` (default store), `users/{uid}` (role: owner), and kicks off Surfboard merchant onboarding.
6. App lands on the Dashboard once `merchantId` is provisioned.

**UI:** Multi-step onboarding wizard (business name → type → address → contact → review). Progress indicator. Cannot be skipped; single continuous flow so a merchant is never left half-registered.

**Backend:** `POST /auth/register` (see [04_API_DOCUMENTATION.md § 2](04_API_DOCUMENTATION.md#2-auth--merchant-onboarding)). Orchestrates: Firebase Admin token verification → RTDB writes → Surfboard onboarding call (see [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)).

**Database:** Writes `merchants/{merchantId}`, `stores/{storeId}`, `users/{uid}`, `settings/{merchantId}` (defaults). See [03_DATABASE_DESIGN.md §4.1–4.3](03_DATABASE_DESIGN.md#4-node-by-node-design).

**Future Improvements:** Document/KYC upload during onboarding; business-category-specific default tax/catalog templates; invite-based team onboarding during registration itself (currently a post-registration step).

---

## 2. Authentication

**Purpose:** Secure, low-friction identity for owners and staff, with role-based access.

**Workflow:**
1. Owner or staff signs in via Firebase Auth (email/password or phone OTP).
2. Flutter app receives a Firebase ID token, attaches it to every backend call via the `ApiClient` interceptor.
3. On first launch after login, app calls `GET /auth/me` to resolve `merchantId`/`storeIds`/`role` and route accordingly (onboarding vs. dashboard).
4. Staff accounts are created via `POST /auth/staff-invite` (owner-only) — staff completes sign-up with the invite code, which links them to the merchant/store without owner-level access.

**UI:** Standard sign-in/sign-up screens; "Forgot password" via Firebase Auth's built-in reset flow; role indicator (owner/staff) in app header/drawer.

**Backend:** `auth.middleware.js` verifies the Bearer token on every protected route. `GET /auth/me`, `POST /auth/staff-invite` (see [04_API_DOCUMENTATION.md § 2](04_API_DOCUMENTATION.md#2-auth--merchant-onboarding)).

**Database:** `users/{uid}` (role, merchantId, storeIds). Firebase Auth itself stores credentials — SurfPOS never stores passwords.

**Future Improvements:** Granular staff permissions (e.g. "can void sales" vs. "can only bill"), biometric app-lock, session device management.

---

## 3. Dashboard

**Purpose:** Give the owner/staff an at-a-glance daily snapshot the moment the app opens.

**Workflow:**
1. On load, app reads `analytics/{storeId}/{today}` via a real-time RTDB listener for instant display, and calls `GET /analytics/:storeId/insights` for the AI insights card.
2. Displays: today's sales total, transaction count, top-selling products, low-stock alert count, and 1–3 AI-generated insights.
3. Tapping any card deep-links into the relevant feature (e.g. low-stock count → Inventory filtered view).

**UI:** Scrollable single-screen card layout (see [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md)); pull-to-refresh; skeleton loaders while first data arrives.

**Backend:** `GET /analytics/:storeId`, `GET /analytics/:storeId/insights` (see [04_API_DOCUMENTATION.md § 10](04_API_DOCUMENTATION.md#10-reports--analytics)).

**Database:** Reads `analytics/{storeId}/{period}` (precomputed rollups — never computed live). See [03_DATABASE_DESIGN.md §4.11](03_DATABASE_DESIGN.md#411-analyticsstoreidperiodmetric).

**Future Improvements:** Customizable dashboard widgets, multi-store aggregate view for owners with several stores, comparison-to-last-period deltas.

---

## 4. Inventory Management

**Purpose:** Give the merchant an always-accurate view of stock per store, with low-stock alerting.

**Workflow:**
1. Owner/staff opens Inventory tab → list of products with current quantity, sorted by low-stock-first (toggle).
2. Manual adjustments (recount, damage, theft write-off) go through `PATCH /inventory/:storeId/:productId` with a signed delta + reason.
3. Stock also changes automatically from two other flows: a completed **Sale** (decrement) and a confirmed **AI Invoice Scan / Purchase Order** (increment) — inventory is never edited ad hoc from those flows; they call the same inventory service internally.
4. Reorder-level breaches surface as a Dashboard alert and (per settings) a push/notification.

**UI:** Filterable/searchable list, quantity badges color-coded by stock health, a manual-adjustment bottom sheet (delta + reason).

**Backend:** `GET /inventory`, `PATCH /inventory/:storeId/:productId` (see [04_API_DOCUMENTATION.md § 5](04_API_DOCUMENTATION.md#5-inventory)). Internally shared `inventory.service.js` is also called by `sales.service.js` and `orders.service.js` — see [07_CODING_RULES.md § Never Duplicate Code](07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services).

**Database:** `inventory/{storeId}/{productId}` (see [03_DATABASE_DESIGN.md §4.5](03_DATABASE_DESIGN.md#45-inventorystoreidproductid)).

**Future Improvements:** Batch/lot tracking, expiry-date tracking, multi-store stock transfer, automatic reorder suggestions feeding directly into a draft purchase order.

---

## 5. Barcode Scanner

**Purpose:** Let the phone camera act as the barcode scanner — no external hardware required — for both billing and inventory lookup.

**Workflow:**
1. User taps the scan icon (from Billing or Inventory).
2. Camera opens with a live barcode-detection overlay (on-device, via the device camera + a barcode-recognition library — no network round-trip needed for detection itself).
3. On successful decode, app looks up the barcode: first against the **locally cached** product catalog (offline-capable — see [02_ARCHITECTURE.md § 12](02_ARCHITECTURE.md#12-offline-strategy)), falling back to `GET /products?barcode=` if not cached.
4. Matched product is added to the active cart (Billing) or opened for stock adjustment (Inventory).
5. If no product matches the barcode, the user is prompted to create a new product with that barcode pre-filled.

**UI:** Full-screen camera view with scan-frame guide, haptic + sound feedback on successful decode, manual barcode text-entry fallback for damaged/unreadable codes.

**Backend:** `GET /products?barcode=` (see [04_API_DOCUMENTATION.md § 4](04_API_DOCUMENTATION.md#4-products-catalog)).

**Database:** Reads `products/{merchantId}` filtered by `barcode` (indexed — see [03_DATABASE_DESIGN.md § 7](03_DATABASE_DESIGN.md#7-indexes)).

**Future Improvements:** Bluetooth barcode-gun support as an optional peripheral, batch-scan mode for rapid multi-item stock-in.

---

## 6. AI Invoice Scanner

**Purpose:** Eliminate manual re-typing of supplier invoices by photographing them and letting OCR + Gemini extract structured line items, matched against the existing product catalog.

**Workflow:** Full pipeline detail lives in [16_AI_MODULE.md](16_AI_MODULE.md). Summary:
1. User photographs a supplier invoice from the Inventory or a dedicated "Scan Invoice" entry point.
2. App uploads the image via `POST /invoice-scans` → backend stores it in Firebase Storage and kicks off async processing (`status: processing`).
3. Backend runs OCR on the image → raw text → sends raw text to Gemini with a structuring prompt → receives `{name, qty, unitPrice}` line items.
4. Backend fuzzy-matches each extracted item name against the merchant's `products` catalog, attaching a `matchConfidence` per item.
5. Scan status flips to `pending_review`; app (listening on the scan node) shows a review screen: each line item, its matched product (editable dropdown if confidence is low), quantity, and cost.
6. Merchant edits if needed and taps **Confirm** → `POST /invoice-scans/:scanId/confirm` → backend creates an `order` and increments `inventory`.
7. Merchant can instead **Reject** the scan entirely.

**UI:** Camera capture screen → processing spinner (async, non-blocking — user can navigate away) → review screen with per-line confidence indicators (e.g. green/yellow/red) and inline edit.

**Backend:** `POST /invoice-scans`, `GET /invoice-scans/:scanId`, `POST /invoice-scans/:scanId/confirm`, `POST /invoice-scans/:scanId/reject` (see [04_API_DOCUMENTATION.md § 6](04_API_DOCUMENTATION.md#6-ai-invoice-scanner)). AI orchestration in `ai.service.js` / `ocr.service.js` (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md), [16_AI_MODULE.md](16_AI_MODULE.md)).

**Database:** Writes `invoiceScans/{merchantId}/{scanId}`; on confirm, writes `orders/{merchantId}/{orderId}` and updates `inventory/{storeId}/{productId}`. See [03_DATABASE_DESIGN.md §4.7–4.8](03_DATABASE_DESIGN.md#47-ordersmerchantidorderid).

**Future Improvements:** Multi-page invoice support, supplier-name learning (auto-fill supplier over time), auto-confirm above a very high confidence threshold (opt-in setting), direct supplier e-invoice ingestion (no photo needed).

---

## 7. Billing

**Purpose:** The core checkout workflow — take payment for a cart of products.

**Workflow:**
1. Cashier builds a cart (see **Cart** below).
2. Taps **Checkout** → app calls `POST /sales` with cart contents.
3. Backend re-validates every item's price/tax/availability against live data (never trusts client totals), creates the `sale` record (`status: pending_payment`) and a Surfboard payment intent for the validated total.
4. App presents the Surfboard payment collection UI/flow (card tap, UPI, wallet — whatever Surfboard supports on the device) for that intent.
5. On payment confirmation (via Surfboard webhook → backend), the sale flips to `completed`, inventory decrements, and a receipt is generated.
6. App (listening on the sale node) transitions automatically to the receipt/confirmation screen.

**UI:** Checkout summary (subtotal/tax/discount/total) → payment method/collection screen → success/failure screen with receipt share options.

**Backend:** `POST /sales`, `POST /sales/:saleId/cancel` (see [04_API_DOCUMENTATION.md § 7](04_API_DOCUMENTATION.md#7-billing--sales)); payment orchestration per [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).

**Database:** Writes `sales/{storeId}/{saleId}`, `payments/{paymentId}`, `receipts/{receiptId}`; updates `inventory/{storeId}/{productId}`. See [02_ARCHITECTURE.md § 7 (Data Flow example)](02_ARCHITECTURE.md#7-data-flow-example-a-sale) for the full sequence.

**Future Improvements:** Split payments (part card, part cash), tipping, held/parked sales (resume later), offline sale queueing (see [02_ARCHITECTURE.md § 12](02_ARCHITECTURE.md#12-offline-strategy)).

---

## 8. Cart

**Purpose:** Local, in-progress collection of items before checkout — the working state of an active sale.

**Workflow:**
1. Items are added via barcode scan or search (see Barcode Scanner / below).
2. Cart is purely **client-side local state** until checkout — no backend write happens per item added, keeping the add-to-cart interaction instant and offline-capable.
3. Quantity can be adjusted or an item removed inline.
4. Discounts (if enabled in settings) can be applied at cart level before checkout.
5. Cart clears automatically on successful checkout or explicit "clear cart."

**UI:** Persistent cart summary bar (item count + running total) visible from the product-search/scan screen; full cart screen with line-item list, quantity steppers, swipe-to-remove.

**Backend:** None directly — the cart only touches the backend once, at checkout (`POST /sales`, see **Billing** above).

**Database:** None directly — cart state is not persisted to Firebase while in progress (Phase 1). See Future Improvements below for the planned exception.

**Future Improvements:** Persist an in-progress cart locally (device storage) so an interrupted app close doesn't lose the cart; "held sales" that *do* sync to the backend so another staff device could resume them.

---

## 9. Payments

**Purpose:** Accept payment for a sale through the Surfboard Payments ecosystem, and keep payment status in sync with sale status.

**Workflow:** See [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) for the full integration contract. Summary: backend creates a payment intent tied to a validated sale total → client collects payment via Surfboard's device/SDK flow → Surfboard sends a webhook on completion → backend reconciles `payments` and `sales` status.

**UI:** Payment-method selection (if multiple rails supported), in-progress spinner during card/UPI capture, clear success/failure state, retry option on failure without re-building the cart.

**Backend:** `GET /payments/:paymentId`, `POST /webhooks/surfboard` (see [04_API_DOCUMENTATION.md § 8](04_API_DOCUMENTATION.md#8-payments-surfboard)).

**Database:** `payments/{paymentId}` (see [03_DATABASE_DESIGN.md §4.9](03_DATABASE_DESIGN.md#49-paymentspaymentid)).

**Future Improvements:** Refunds/partial refunds workflow, saved customer payment methods (if/when Surfboard supports it), multi-device payment collection (one device bills, another collects payment).

---

## 10. Receipt

**Purpose:** Give every sale a durable, shareable digital record — replacing (or supplementing) a paper receipt.

**Workflow:**
1. On sale completion, backend generates a receipt PDF (from a merchant-configurable template — see Settings), uploads it to Firebase Storage, and writes the `receipts` record.
2. App shows the receipt immediately and offers share options (SMS/email/WhatsApp link, or print if a peripheral is connected in the future).

**UI:** Receipt preview screen mirroring the PDF layout; share sheet; access to past receipts from Sales/Reports history.

**Backend:** `GET /receipts/:receiptId`, `POST /receipts/:receiptId/share` (see [04_API_DOCUMENTATION.md § 9](04_API_DOCUMENTATION.md#9-receipts)).

**Database:** `receipts/{receiptId}` + PDF in Firebase Storage (see [03_DATABASE_DESIGN.md §4.10](03_DATABASE_DESIGN.md#410-receiptsreceiptid)).

**Future Improvements:** Bluetooth thermal printer support, itemized tax-invoice format for GST compliance, customer-facing receipt lookup portal.

---

## 11. Reports

**Purpose:** Let the merchant look back at sales/inventory history beyond the live dashboard snapshot.

**Workflow:**
1. Merchant opens Reports, picks a date range and dimension (sales, top products, payment methods, invoice/purchase history).
2. App queries `GET /sales` (paginated) and/or `GET /analytics/:storeId?period=` for pre-aggregated ranges.
3. Reports can be exported (future) or viewed in-app with simple charts/tables.

**UI:** Date-range picker, tabbed report types, simple bar/line charts (see [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md)), tap-through to underlying sale detail.

**Backend:** `GET /sales`, `GET /analytics/:storeId` (see [04_API_DOCUMENTATION.md §§ 7, 10](04_API_DOCUMENTATION.md#7-billing--sales)).

**Database:** Reads `sales/{storeId}` (paginated, indexed by `createdAt`) and `analytics/{storeId}/{period}`.

**Future Improvements:** CSV/PDF export, scheduled email reports, custom report builder.

---

## 12. Analytics & AI Business Insights

**Purpose:** Turn raw sales data into decisions the merchant can act on, without requiring them to interpret raw numbers themselves.

**Workflow:**
1. A scheduled backend job aggregates raw `sales` into `analytics/{storeId}/{period}` rollups (daily and monthly) — see [02_ARCHITECTURE.md § 10](02_ARCHITECTURE.md#10-scalability).
2. Periodically (or on-demand), the backend sends recent aggregates to Gemini with an insight-generation prompt (e.g. "identify notable trends, slow movers, and restocking suggestions") — detail in [16_AI_MODULE.md](16_AI_MODULE.md).
3. Insights are surfaced on the Dashboard and in Reports, written in plain language with a suggested action where applicable (e.g. "Reorder Wax — Tropical: 6 days of stock left at current sales pace").

**UI:** Insight cards with icon/severity (info/warning), tap-through to the relevant product/report.

**Backend:** `GET /analytics/:storeId/insights` (see [04_API_DOCUMENTATION.md § 10](04_API_DOCUMENTATION.md#10-reports--analytics)); generation job in `ai.service.js`.

**Database:** Reads `analytics/{storeId}/{period}`; insights themselves may be cached under `analytics/{storeId}/{period}/insights` or a dedicated sub-node (implementation detail to confirm at build time — record the final choice in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)).

**Future Improvements:** Predictive restocking with seasonality, anomaly detection (fraud/shrinkage signals), natural-language "ask your data" chat interface powered by Gemini.

---

## 13. Settings

**Purpose:** Merchant-level configuration that affects tax computation, receipts, notifications, and staff.

**Workflow:**
1. Owner opens Settings → sections for Business Profile, Tax, Receipt Template, Notifications, Staff Management.
2. Each section reads/writes via `GET/PATCH /settings/:merchantId` (or the dedicated merchant/staff endpoints for those sub-domains).

**UI:** Standard settings list → detail screens per section; staff list with invite/remove actions (owner-only).

**Backend:** `GET /settings/:merchantId`, `PATCH /settings/:merchantId`, plus `POST /auth/staff-invite`, `PATCH /merchants/:merchantId` (see [04_API_DOCUMENTATION.md §§ 2, 3, 11](04_API_DOCUMENTATION.md#11-settings)).

**Database:** `settings/{merchantId}`, `merchants/{merchantId}`, `users/{uid}` (see [03_DATABASE_DESIGN.md §4.12](03_DATABASE_DESIGN.md#412-settingsmerchantid)).

**Future Improvements:** Per-store settings overrides (multi-store), configurable role permissions, data export/account deletion self-service (compliance).

---

**Next:** [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md) — visual design system referenced throughout this document.
