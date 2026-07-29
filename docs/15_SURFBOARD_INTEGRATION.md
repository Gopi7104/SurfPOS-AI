# 15 — Surfboard Payments Integration

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase). Related: [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md) (entity lifecycles), [21_BACKEND_GUIDELINES.md § 5](21_BACKEND_GUIDELINES.md#5-integration-client-surfboard-owned-entities-only) (code layer contract), [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md).
>
> **Accuracy note:** the *ownership model* below — Surfboard is the system of record for Merchant, Store, Device, Payment, Branding, Tips, and Payment Methods — is a confirmed architectural decision (see [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)). The **exact endpoint paths, request/response field names, and auth mechanism are still illustrative**, pending confirmation against Surfboard's official developer documentation and sandbox credentials — do not treat a specific field name in this file as verified wire format. Update this file once confirmed, per [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made).

---

## 1. Integration Principle

**Surfboard is the system of record for seven entities — Merchant, Store, Device, Payment, Branding, Tips, Payment Methods — not just a payment processor bolted onto a SurfPOS-owned merchant record.** See [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle) for what this means concretely: SurfPOS AI never persists a full copy of any of these seven in Firebase; it holds only the ID needed to ask Surfboard for the current truth.

All Surfboard API calls happen **server-side only**, from the Node/Express backend's Integration Layer (`src/integrations/surfboard/`). The Flutter app never holds a Surfboard API key/secret and never calls Surfboard directly — it only ever talks to the SurfPOS backend (see [02_ARCHITECTURE.md § 1](02_ARCHITECTURE.md#1-system-architecture-high-level)). Where Surfboard requires client-side SDK involvement (e.g. a card-entry/tap-to-pay UI on the device), the client uses a short-lived token/client secret issued by the backend for that specific transaction — never the merchant's underlying API credentials.

## 2. Authentication (Backend ↔ Surfboard)

- The backend authenticates to Surfboard's API using platform-level credentials (`SURFBOARD_API_KEY` / `SURFBOARD_API_SECRET`, see [14_DEVELOPER_GUIDE.md § 6](14_DEVELOPER_GUIDE.md#6-environment-variables)) — confirm whether Surfboard uses API-key headers, OAuth2 client-credentials, or another scheme, and update this section accordingly. The SDK now implements this as a swappable strategy (`SURFBOARD_AUTH_STRATEGY=api_key|bearer|oauth`, see [ADR-019](08_ARCHITECTURE_DECISIONS.md#adr-019--surfboard-sdk-authentication-layer-strategy-pattern-extends-phase-2-not-roadmap-phase-3)), so confirming the real scheme means selecting/adding a strategy in `integrations/surfboard/auth/strategies/`, not rewriting the request pipeline.
- Two environments must be kept fully separate in configuration: `sandbox` and `production` — never mix credentials or point a dev build at production.
- All seven client files in `src/integrations/surfboard/` share one base request/auth implementation (`surfboardClient.base.js`, already scaffolded) so a credential/auth-scheme change is a one-file fix, not seven.

## 3. Merchant Lifecycle

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle). Summary of the integration contract:

- `integrations/surfboard/merchant.client.js` exposes create/get/update operations against Surfboard's Merchant API.
- Onboarding may be asynchronous (KYC review) — the backend reflects Surfboard's own onboarding/status field live; it does not invent a parallel `status` field in Firebase.
- **To confirm against official docs:** required KYC fields/documents, sync vs. async onboarding, whether a webhook or polling reveals onboarding completion.

## 4. Store Lifecycle

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 2](19_SURFBOARD_WORKFLOWS.md#2-store-lifecycle). `integrations/surfboard/store.client.js` exposes create/get/update Store operations **and** Payment Methods querying/configuration (folded in per [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split) — Payment Methods are a capability of a Store, not a standalone domain worth its own client file).

## 5. Payment Lifecycle

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle).

### 5.1 Creating a payment (checkout flow)

- Once `billing.service.js` validates a cart total and creates a Firebase-owned Sale (`pending_payment`), `payments.service.js` calls `integrations/surfboard/payment.client.js` to create a payment intent for that exact validated amount, tied to the Store (and Device, if card-present).
- The resulting Surfboard payment identifier is stored as `sales/{storeId}/{saleId}.surfboardPaymentId` — **not** as a duplicated `payments/{paymentId}` Firebase record (that node no longer exists — see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).
- **Never** create the payment intent for a client-submitted amount directly — only for the backend-recomputed total.

### 5.2 Collecting payment (client-side)

- Depending on which rails the Store's Payment Methods (§ 4) support, the Flutter app either invokes a Surfboard-provided mobile SDK flow or displays a QR/deep-link.
- **To confirm against official docs:** whether Surfboard provides a Flutter/Dart SDK directly, a platform-native SDK requiring a plugin wrapper, or a purely server-driven flow (QR/link) with no client SDK — this affects [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) (whether a `surfboard_sdk` wrapper package is needed in `frontend/`).

### 5.3 Confirming payment status

- Primary mechanism: **webhook** (§ 7). The backend never relies on the client to report success.
- Secondary/fallback: the backend can poll Surfboard's payment-status endpoint via `payment.client.js` if a webhook hasn't arrived within an expected window, or when a user opens a "payment details" screen and needs the full, current Payment object (which, per § 1, is never reconstructed from Firebase — it's always a live call).
- Tips collected as part of a payment flow through the same client — see [19_SURFBOARD_WORKFLOWS.md § 6](19_SURFBOARD_WORKFLOWS.md#6-tips-workflow).

## 6. Device Lifecycle

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 3](19_SURFBOARD_WORKFLOWS.md#3-device-lifecycle). `integrations/surfboard/device.client.js` exposes link/unlink/status operations. Device status is always queried live — never cached in Firebase, since a device can go offline independent of any SurfPOS-side event.

## 7. Webhooks

- Endpoint: `POST /webhooks/surfboard` (see [04_API_DOCUMENTATION.md § 8](04_API_DOCUMENTATION.md#8-payments-surfboard)).
- **Signature verification is mandatory** — every incoming webhook is verified against `SURFBOARD_WEBHOOK_SECRET` (exact signing scheme to confirm against official docs) before any data is trusted or written.
- **Idempotency is mandatory** — the handler must check whether this event ID has already been processed before acting a second time.
- On a verified `payment.succeeded`-equivalent event: `sales/{storeId}/{saleId}.status = "completed"`, `paymentStatus = "paid"`, decrement Inventory, trigger Receipt generation — all Firebase-owned writes, none of which duplicate the Payment object itself (see § 5.1).
- On a verified failure event: `paymentStatus = "failed"`, Sale stays retryable.
- The webhook handler is owned by `modules/payments/payments.service.js` (see [21_BACKEND_GUIDELINES.md § 13](21_BACKEND_GUIDELINES.md#13-folder-ownership-summary)); if Surfboard's webhook payload ever carries non-payment event types (merchant/device status changes), those route to the owning module's Service, not handled inline in the Payments handler.

## 8. Branding Workflow

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 5](19_SURFBOARD_WORKFLOWS.md#5-branding-workflow). `integrations/surfboard/branding.client.js` exposes get/update operations against Surfboard's own checkout/receipt branding. This is **not** the same object as SurfPOS's own `settings/{merchantId}.receiptTemplate` (Firebase-owned) — the two are deliberately kept separate since they control different rendering surfaces.

## 9. Payment Methods Workflow

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 7](19_SURFBOARD_WORKFLOWS.md#7-payment-methods-workflow). Folded into `store.client.js` (§ 4) — queried live before checkout to decide which payment-collection UI to present.

## 10. Tips Workflow

Full step-by-step sequence: [19_SURFBOARD_WORKFLOWS.md § 6](19_SURFBOARD_WORKFLOWS.md#6-tips-workflow). Folded into `payment.client.js` (§ 5) — tip configuration and tip amounts are both payment-adjacent concerns.

## 11. Workflow Summary (End-to-End)

```
Merchant Creation: SurfPOS backend → Surfboard Merchant Creation → merchantId reference stored
Store Creation:    SurfPOS backend → Surfboard Store Creation → storeId reference stored
Checkout:          SurfPOS backend validates cart (Firebase) → creates Surfboard payment intent
Collection:        Flutter app → Surfboard SDK/QR flow → customer completes payment
Confirmation:      Surfboard → webhook → SurfPOS backend verifies signature → updates
                   Sale/Inventory/Receipt (Firebase) — never a duplicated Payment record
Reconciliation:    (fallback) SurfPOS backend polls payment status if webhook is late/missing
Device/Branding/
Payment Methods/
Tips:              Queried/configured live via their respective clients — never cached in
                   Firebase (see 20_DOMAIN_MODEL.md § 1)
```

## 12. Future APIs

- **Refunds/partial refunds** — not scoped yet (see [19_SURFBOARD_WORKFLOWS.md § 4](19_SURFBOARD_WORKFLOWS.md#4-payment-lifecycle) step 7); a Surfboard refund call plus a Sale status of `refunded`/`partially_refunded` — no new Firebase entity needed, consistent with the no-duplication principle.
- **Settlement/payout reporting** — surfacing Surfboard settlement data inside Reports/Analytics is future scope.
- **Multi-device payment collection** — future scope, depends on Surfboard's device-linking model (§ 6).
- **Split payments** (part card, part cash) — future scope; would need Sale to reference more than one `surfboardPaymentId`.

---

**Next:** [19_SURFBOARD_WORKFLOWS.md](19_SURFBOARD_WORKFLOWS.md) if arriving here first, otherwise [16_AI_MODULE.md](16_AI_MODULE.md) — the OCR + Gemini AI pipeline (unaffected by this pass).
