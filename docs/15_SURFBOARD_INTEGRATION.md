# 15 — Surfboard Payments Integration

> **Important accuracy note:** This document describes the **integration pattern** SurfPOS AI's backend should follow for Surfboard Payments, based on how payment platforms of this type are generally structured (merchant onboarding, payment intents, device linkage, webhooks). The **exact endpoint paths, request/response shapes, and auth mechanism must be confirmed against Surfboard's official developer documentation and sandbox credentials** before implementation — do not treat the specifics below as verified. Once confirmed, update this file and log the confirmed details as a new ADR in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (see ADR-009). Related: [02_ARCHITECTURE.md § 6](02_ARCHITECTURE.md#6-surfboard-payments-layer), [04_API_DOCUMENTATION.md § 8](04_API_DOCUMENTATION.md#8-payments-surfboard), [05_FEATURES.md § 9](05_FEATURES.md#9-payments).

---

## 1. Integration Principle

**All Surfboard Payments calls happen server-side, from the Node/Express backend only.** The Flutter app never holds a Surfboard API key/secret. Where Surfboard requires client-side SDK involvement (e.g. presenting a card-entry UI or tap-to-pay flow on the device), the client uses a short-lived token/client secret issued by the backend for that specific transaction — never the merchant's underlying API credentials.

## 2. Authentication (Backend ↔ Surfboard)

- The backend authenticates to Surfboard's API using credentials issued for this merchant/platform integration (`SURFBOARD_API_KEY` / `SURFBOARD_API_SECRET`, see [14_DEVELOPER_GUIDE.md § 6](14_DEVELOPER_GUIDE.md#6-environment-variables)) — confirm whether Surfboard uses API-key headers, OAuth2 client-credentials, or another scheme, and update this section accordingly.
- Two environments must be kept fully separate in configuration: `sandbox` (development/testing) and `production` — never mix credentials or point a dev build at production.

## 3. Merchant Onboarding (Surfboard Merchant API)

- Triggered automatically as part of [Merchant Registration](05_FEATURES.md#1-merchant-registration) (`POST /auth/register` on the SurfPOS backend).
- Conceptually: the backend submits the merchant's business details to Surfboard's merchant/KYC onboarding endpoint, receives back a Surfboard-side merchant identifier, and stores it as `merchants/{merchantId}.surfboardMerchantId` (see [03_DATABASE_DESIGN.md § 4.2](03_DATABASE_DESIGN.md#42-merchantsmerchantid)).
- Onboarding may be asynchronous (KYC review) — `merchants/{merchantId}.status` should reflect this (`pending_verification` → `active`) rather than assuming instant activation. The app should allow the merchant to explore the app in a "payments pending verification" state rather than blocking all access.
- **To confirm against official docs:** required KYC fields/documents, sync vs. async onboarding, and whether a webhook or polling is used to learn onboarding completion.

## 4. Payment APIs

### 4.1 Creating a payment (checkout flow)

- Conceptually maps to [05_FEATURES.md § 7 Billing](05_FEATURES.md#7-billing) step 3: once the backend validates a cart total (`POST /sales` in [04_API_DOCUMENTATION.md § 7](04_API_DOCUMENTATION.md#7-billing--sales)), it creates a **payment intent/charge** with Surfboard for that exact validated amount, tied to the merchant's `surfboardMerchantId`.
- The resulting Surfboard payment-intent identifier is stored on `payments/{paymentId}.surfboardPaymentIntentId` (see [03_DATABASE_DESIGN.md § 4.9](03_DATABASE_DESIGN.md#49-paymentspaymentid)) and returned to the client so it can proceed with the collection step (§4.2).
- **Never** create the payment intent for a client-submitted amount directly — only for the backend-recomputed total (see [07_CODING_RULES.md § 8](07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services)).

### 4.2 Collecting payment (client-side)

- Depending on which rails Surfboard supports for this merchant/device (card-present tap-to-pay, UPI/QR, wallet), the Flutter app either invokes a Surfboard-provided mobile SDK flow or displays a QR/deep-link for the customer to complete payment.
- **To confirm against official docs:** whether Surfboard provides a Flutter/Dart SDK directly, a platform-native SDK requiring a plugin wrapper, or a purely server-driven flow (QR/link) with no client SDK at all — this materially affects [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) (whether a `surfboard_sdk` wrapper package is needed in `frontend/`).

### 4.3 Confirming payment status

- Primary mechanism: **webhook** (§5) — the backend should not rely on the client to report success, since a closed app or dropped connection shouldn't be able to fake a completed sale.
- Secondary mechanism (fallback/reconciliation): the backend can poll Surfboard's payment-status endpoint for a given payment-intent ID if a webhook hasn't arrived within an expected window (protects against missed webhook delivery).

## 5. Webhooks

- Endpoint: `POST /webhooks/surfboard` (see [04_API_DOCUMENTATION.md § 8](04_API_DOCUMENTATION.md#8-payments-surfboard)).
- **Signature verification is mandatory** — every incoming webhook must be verified against `SURFBOARD_WEBHOOK_SECRET` (exact signing scheme — HMAC header, etc. — to confirm against official docs) before any data is trusted or written.
- **Idempotency is mandatory** — Surfboard (like most payment providers) may retry webhook delivery; the handler must check whether this event ID has already been processed before acting a second time (see [07_CODING_RULES.md § 15](07_CODING_RULES.md#15-nodejs-best-practices)).
- On a verified `payment.succeeded`-equivalent event: mark `payments/{paymentId}.status = "succeeded"`, flip the linked `sales/{storeId}/{saleId}.status = "completed"`, decrement inventory, and trigger receipt generation — the exact orchestration sequence is in [02_ARCHITECTURE.md § 7](02_ARCHITECTURE.md#7-data-flow-example-a-sale).
- On a verified failure event: mark `payments/{paymentId}.status = "failed"` and leave the sale in a state the app can offer to retry from (see [05_FEATURES.md § 9 UI](05_FEATURES.md#9-payments)).

## 6. Device APIs

- If a merchant uses a Surfboard-provided physical card reader/device (rather than phone-only tap-to-pay), the device must be **linked** to the merchant/store, likely via a device-pairing API call, and its identifier stored — candidate field `payments/{paymentId}.surfboardDeviceId` (already reserved in the schema, see [03_DATABASE_DESIGN.md § 4.9](03_DATABASE_DESIGN.md#49-paymentspaymentid)).
- Device management (list linked devices, unlink, check device status) would live under its own settings sub-section — **not yet scoped as a Phase 1 endpoint**; add to [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md) and [10_TASKS.md](10_TASKS.md) once Surfboard's device-support model for this integration is confirmed.

## 7. Workflow Summary (End-to-End)

```
Registration:  SurfPOS backend → Surfboard merchant onboarding → surfboardMerchantId stored
Checkout:      SurfPOS backend validates cart → creates Surfboard payment intent
Collection:    Flutter app → Surfboard SDK/QR flow → customer completes payment
Confirmation:  Surfboard → webhook → SurfPOS backend verifies signature → updates
               payments/sales/inventory/receipts (see 02_ARCHITECTURE.md § 7)
Reconciliation:(fallback) SurfPOS backend polls payment status if webhook is late/missing
```

## 8. Future APIs

- **Refunds/partial refunds** — not scoped for Phase 1 (see [05_FEATURES.md § 9 Future Improvements](05_FEATURES.md#9-payments)); will need a Surfboard refund endpoint plus a `sales` status of `refunded`/`partially_refunded`.
- **Settlement/payout reporting** — surfacing Surfboard settlement data (when funds actually reach the merchant's bank account) inside Reports/Analytics is future scope.
- **Multi-device payment collection** (one device bills, a separate linked device collects payment) — future scope, depends on confirming Surfboard's device-linking model (§6).
- **Split payments** (part card, part cash) — future scope, needs a `payments` schema extension to support multiple payment records per sale.

---

**Next:** [16_AI_MODULE.md](16_AI_MODULE.md) — the OCR + Gemini AI pipeline.
