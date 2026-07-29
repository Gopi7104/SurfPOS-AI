# 19 — Surfboard Workflows

> **New document, added during the Surfboard-alignment documentation pass.** Prerequisite reading: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md). This document walks each Surfboard-owned entity through its full lifecycle as SurfPOS AI orchestrates it — [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) describes the integration *contract* (auth, webhooks, error handling); this describes the *sequence of events* for each entity end to end.
>
> **Accuracy note (same caveat as [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md)):** the *ownership model* below (Surfboard is the system of record for these entities) is a confirmed architectural decision. The *exact* Surfboard endpoint names/payload shapes referenced are still illustrative pending confirmation against Surfboard's official developer documentation and sandbox credentials — do not treat a specific field name below as verified.

---

## 1. Merchant Lifecycle

```
1. Owner completes SurfPOS sign-up (Firebase Auth) and the business-details form.
2. SurfPOS backend calls integrations/surfboard/merchant.client.js → Surfboard Merchant
   Creation API, submitting business details.
3. Surfboard returns a merchant identifier + an onboarding/KYC status
   ("pending_verification" | "active" | ...).
4. SurfPOS backend writes ONLY the reference: users/{uid}.merchantId = <surfboard merchant id>.
   No business fields are copied into Firebase (see 20_DOMAIN_MODEL.md § 2.1).
5. If onboarding is asynchronous (KYC review), the merchant can use non-payment features
   immediately; anything requiring active payment capability checks live merchant status
   via merchant.client.js before allowing checkout.
6. Merchant profile updates (name, address, contact info) are read/written live via
   merchant.client.js — GET/PATCH proxy endpoints, never a Firebase write.
```

**Owning module:** `src/modules/merchant/merchant.service.js`. **Roadmap phase:** [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md) Phase 4 (Merchant Creation) + Phase 5 (Merchant Functions).

## 2. Store Lifecycle

```
1. A default Store is created as part of Merchant Creation (Phase 4) — one store per
   merchant at first registration, via integrations/surfboard/store.client.js.
2. SurfPOS backend writes ONLY the reference: users/{uid}.storeIds[<surfboard store id>] = true.
3. Store profile (name, address) and capabilities (which payment methods/tips this store
   supports — see §§ 6–7) are read live via store.client.js, never duplicated in Firebase.
4. Every Firebase app-data node that needs to be scoped per location partitions by this
   Store ID (inventory/{storeId}/..., sales/{storeId}/...) — the ID is a foreign key, not
   an invitation to also copy the Store's business fields alongside it.
5. Additional stores (multi-store, future scope per 01_PROJECT_OVERVIEW.md) are created the
   same way — one Surfboard Store Creation call per new location.
```

**Owning module:** `src/modules/store/store.service.js`. **Roadmap phase:** Phase 6 (Store Capabilities).

## 3. Device Lifecycle

```
1. Merchant/staff initiates device linking from Settings (future UI — see 05_FEATURES.md).
2. SurfPOS backend calls integrations/surfboard/device.client.js → Surfboard Device
   Linking API, associating a physical card reader with a Store.
3. Surfboard returns a device identifier + status ("linked").
4. Device status/health (linked/unlinked/offline, last-seen) is queried live via
   device.client.js whenever Settings or a pre-checkout device check needs it — never
   cached as a Firebase record (device status changes independent of SurfPOS's own state).
5. A completed Payment (§ 4) may reference which Device processed it
   (Payment.deviceId) — that is a transaction-time fact captured on the Payment itself,
   not a reason to give Device its own Firebase-side history.
6. Unlinking follows the reverse call; SurfPOS drops any transaction-time references it
   was holding but never held a durable Device record to clean up.
```

**Owning module:** `src/modules/device/device.service.js`. **Roadmap phase:** Phase 10 (Device Management).

## 4. Payment Lifecycle

```
1. Cashier checks out a cart (Billing, Phase 8) → SurfPOS backend validates the cart
   against live Product prices (Firebase-owned) and creates a Sale record
   (status: pending_payment) — see 20_DOMAIN_MODEL.md § 2.10.
2. SurfPOS backend calls integrations/surfboard/payment.client.js → Surfboard Payment
   Creation API for the validated grand total, tied to the Store (and Device, if
   card-present).
3. Surfboard returns a payment identifier; SurfPOS writes ONLY
   sales/{storeId}/{saleId}.surfboardPaymentId — no amount/method/status copy beyond the
   minimal cached paymentStatus enum used for the Sale's own state machine
   (see 20_DOMAIN_MODEL.md § 2.4).
4. Flutter app collects payment via whichever Surfboard-supported flow applies
   (device tap, QR/link) — see 15_SURFBOARD_INTEGRATION.md § 5.
5. Surfboard sends a webhook (POST /webhooks/surfboard) on completion/failure.
   SurfPOS backend verifies the signature, then:
     a. On success: sales/{storeId}/{saleId}.status = "completed",
        paymentStatus = "paid"; decrement Inventory (Firebase-owned); generate Receipt
        (Firebase-owned).
     b. On failure: paymentStatus = "failed"; Sale stays retryable.
6. A "payment details" screen (e.g. for a refund investigation) fetches the FULL Payment
   object live from payment.client.js by surfboardPaymentId — SurfPOS never reconstructs
   it from Firebase fields, because it never stored more than the reference + status enum.
7. Refunds (future scope) follow the same shape: a call to payment.client.js, a webhook
   confirming it, and a Sale status update to "refunded" — no new Firebase entity needed.
```

**Owning module:** `src/modules/payments/payments.service.js` (webhook handler lives here too). **Roadmap phase:** Phase 9 (Payments).

## 5. Branding Workflow

```
1. Merchant configures branding (logo, primary color, receipt footer text recognized by
   Surfboard's own checkout/receipt surfaces) via a Settings screen.
2. SurfPOS backend calls integrations/surfboard/branding.client.js → Surfboard Branding
   API (GET to display current values, PATCH to update).
3. Nothing is cached in Firebase. SurfPOS's OWN receipt template
   (settings/{merchantId}.receiptTemplate, Firebase-owned — see 20_DOMAIN_MODEL.md § 2.6)
   is a separate, deliberately non-merged concept: it controls SurfPOS-generated PDF
   receipts, not Surfboard's checkout-time branding.
```

**Owning module:** `src/modules/branding/branding.service.js`. **Roadmap phase:** Phase 11 (Branding).

## 6. Tips Workflow

```
1. Merchant enables/configures tipping (on/off, preset percentages) for a Store via
   Settings.
2. SurfPOS backend calls integrations/surfboard/payment.client.js (tips are configured
   and collected as part of the payment flow, not a separate client — see
   08_ARCHITECTURE_DECISIONS.md § ADR-016) → Surfboard's tip-configuration API.
3. At checkout, if tipping is enabled, the tip amount is captured as part of Payment
   collection (§ 4 step 4) and returned on the Payment object — SurfPOS reflects it in
   the Sale's grandTotal (a Firebase-owned computed value) but does not separately own
   tip configuration or tip history.
```

**Owning module:** `src/modules/payments/payments.service.js` (tip config is a Payments-module concern). **Roadmap phase:** folded into Phase 9 (Payments) — see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md).

## 7. Payment Methods Workflow

```
1. Merchant/staff views which payment rails a Store currently accepts (card, Swish,
   wallet, etc.) via Settings → Store Capabilities.
2. SurfPOS backend calls integrations/surfboard/store.client.js (Payment Methods are
   queried/configured as a Store capability, not a separate client — see
   08_ARCHITECTURE_DECISIONS.md § ADR-016) → Surfboard's payment-methods API for that
   Store.
3. The checkout flow (§ 4) reads this live to decide which payment-collection UI to
   present — never from a Firebase cache, since available rails can change independent
   of any SurfPOS-side event.
```

**Owning module:** `src/modules/store/store.service.js`. **Roadmap phase:** folded into Phase 6 (Store Capabilities) — see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md).

---

**Next:** [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) if arriving here first, otherwise [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) for how these workflows map to actual backend code layers.
