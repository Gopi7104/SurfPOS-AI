# 02 — Architecture

> **Rewritten during the Surfboard-alignment documentation pass (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md)) — supersedes all earlier versions of this file.** Prerequisite reading: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md). Related: [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md), [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md), [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md).

---

## 1. System Architecture (High Level)

SurfPOS AI is a **client-server, cloud-native, multi-tenant** system with **two systems of record**, not one:

```
                              ┌──────────────────────────┐
                              │      FLUTTER APP          │
                              │  Auth · Dashboard ·        │
                              │  Inventory · Scanner ·     │
                              │  Billing · Reports         │
                              └───────────┬────────────────┘
                                          │ REST (HTTPS/JSON) — all traffic
                                          ▼
                              ┌──────────────────────────┐
                              │   NODE.JS + EXPRESS API    │
                              │  Controllers → Services    │
                              └───────────┬────────────────┘
                        ┌─────────────────┴─────────────────┐
                        ▼                                    ▼
          ┌──────────────────────────┐        ┌──────────────────────────────┐
          │  REPOSITORIES (Firebase)  │        │  SURFBOARD INTEGRATION LAYER  │
          │  Inventory · Product ·    │        │  Merchant · Store · Device ·  │
          │  Sale · Order · Invoice-  │        │  Payment · Branding · Tips ·  │
          │  Scan · Receipt ·         │        │  Payment Methods              │
          │  Analytics · Settings ·   │        └───────────┬───────────────────┘
          │  Supplier · User          │                    │
          └───────────┬────────────────┘                    ▼
                      ▼                          ┌──────────────────────┐
          ┌──────────────────────────┐            │   SURFBOARD APIS      │
          │  FIREBASE RTDB / STORAGE  │            └──────────────────────┘
          └──────────────────────────┘

                (AI Layer — OpenRouter + OCR — hangs off Domain Services the
                 same way Repositories do; see § 5)
```

**The Flutter app talks only to the Node/Express backend — never directly to Firebase or Surfboard.** This is a deliberate change from earlier plans (see [08_ARCHITECTURE_DECISIONS.md § ADR-014](08_ARCHITECTURE_DECISIONS.md#adr-014--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods)): with two systems of record instead of one, the backend is the only place that knows which one to ask for a given piece of data, and the only place that can enforce "never duplicate a Surfboard object" (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). A client that read Firebase directly could not tell the difference between "this is genuinely missing" and "this data lives in Surfboard, not here."

## 2. Frontend (Flutter)

- **Pattern:** Feature-first modules, each internally split into `data / domain / presentation` (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).
- **State management:** Riverpod (see [08_ARCHITECTURE_DECISIONS.md § ADR-007](08_ARCHITECTURE_DECISIONS.md#adr-007--state-management-riverpod-flutter) — still Proposed, unaffected by this pass).
- **Navigation:** `go_router`.
- **Network layer:** a single `ApiClient` wrapper (`dio`) for **all** backend calls — there is no second Firebase-SDK-direct code path anymore. Auth token attached via interceptor.
- **Responsibilities:** render UI, capture input, run client-side validation (feedback only), and call the backend for literally everything else — money, stock, AI, and now also merchant/store/device/payment/branding data, all of which live behind the backend regardless of which system of record answers.
- **Open item — real-time strategy:** the pre-existing design leaned on Firebase RTDB's real-time listeners (direct client access) for "instant" dashboard/sale-status updates. Removing direct Firebase access (this revision) removes that mechanism along with it. Whether the client now polls, or the backend adds a push/streaming channel (WebSocket/SSE), is **not yet decided** — track as a new open item alongside [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) and resolve before Phase 8 (Billing) needs sale-status updates or Phase 12 (Analytics) needs dashboard updates.

## 3. Backend (Node.js + Express)

- **Pattern:** Layered — `routes → controllers → services → { repositories (Firebase) | integration clients (Surfboard) }`. Full detail: [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).
- **Responsibilities:**
  - Verify every incoming request's Firebase ID token (`auth.middleware.js`) — Firebase Authentication remains SurfPOS's identity provider regardless of the Merchant/Store ownership change (identity is not a Surfboard concept).
  - Own all business logic that must not run on the client, exactly as before: sale totals/tax computation, inventory decrement, invoice-to-inventory reconciliation, analytics aggregation.
  - Own the **only** code path that talks to Surfboard, through the Integration Layer (§ 5), and the **only** code path that talks to Firebase for application data, through Repositories (§ 4).
  - Never store secrets or service credentials on the client. Every third-party secret (OpenRouter API key, Surfboard API keys, Firebase service account) lives only in backend environment variables.
- **The backend has no primary datastore of its own.** For application data it reads/writes Firebase RTDB via Repositories. For Merchant/Store/Device/Payment/Branding/Tips/Payment Methods it has **no datastore at all** — it calls Surfboard live every time, because Surfboard is the datastore for those entities (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)).

## 4. Data Ownership: Surfboard vs. Firebase

This is the central architectural fact of SurfPOS AI as of this revision — everything else in this document follows from it.

| Owned by **Surfboard** (fetched live, never duplicated) | Owned by **Firebase** (application data) |
|---|---|
| Merchant | Inventory |
| Store | Product |
| Device | Sale |
| Payment | Order |
| Branding | InvoiceScan |
| Tips | Receipt |
| Payment Methods | Analytics |
| | Settings |
| | Supplier |
| | User (app profile — identity itself is Firebase Authentication) |

Full entity definitions and the ID-reference rule that keeps this split enforceable: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md).

**Consequence for every future schema/endpoint decision:** before adding a Firebase field or a new RTDB node, check whether it duplicates something in the left column. If it does, it's a bug — fetch it from Surfboard instead (see [21_BACKEND_GUIDELINES.md § 4–5](21_BACKEND_GUIDELINES.md#4-repository-firebase-owned-entities-only) for exactly how).

## 5. Repositories, Integration Clients, and the AI Layer

Domain Services (`src/modules/<domain>/`) sit above two parallel data-access paths, plus a third for AI:

1. **Repositories** (`<domain>.repository.js`) — the only code that calls the Firebase Admin SDK, one per Firebase-owned entity.
2. **Surfboard Integration Layer** (`src/integrations/surfboard/<domain>.client.js`) — the only code that calls a Surfboard API, one per Surfboard-owned domain.
3. **AI Layer** (`src/modules/ai/`) — OCR + OpenRouter, called only from the backend (never the client, so API keys stay server-side and output is validated before touching Firebase). Unchanged in shape from earlier plans — the AI layer's inputs/outputs are entirely Firebase-owned data (InvoiceScan, Analytics), so it doesn't touch Surfboard at all.

Full layering contract, including the Mapper/Validator sub-layers and the cross-module calling rule: [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).

## 6. Data Flow (Example: A Sale)

```
1. Cashier scans/searches products (Firebase-owned Product catalog, via backend) → builds
   cart (local Flutter state).
2. Cashier taps "Checkout" → app calls POST /sales on the backend.
3. billing.service.js validates the cart against live Product prices (Firebase-owned,
   via products.repository.js) — never trusts client-submitted prices/totals.
4. billing.service.js creates a Sale record (Firebase-owned, status: pending_payment)
   via sales.repository.js.
5. payments.service.js calls integrations/surfboard/payment.client.js to create a
   Surfboard payment intent for the validated total, tied to the Store/Device.
6. Backend stores ONLY sales/{storeId}/{saleId}.surfboardPaymentId — see
   20_DOMAIN_MODEL.md § 2.10.
7. App collects payment via Surfboard's device/SDK/QR flow (see
   15_SURFBOARD_INTEGRATION.md § 5).
8. Surfboard sends a webhook to POST /webhooks/surfboard confirming payment status.
9. Backend, on confirmed payment:
     a. Writes sales/{storeId}/{saleId}.status = "completed" (Firebase-owned)
     b. Decrements inventory/{storeId}/{productId} (Firebase-owned, via
        inventory.service.js — never duplicated logic, see 21_BACKEND_GUIDELINES.md § 8)
     c. Generates a receipt → writes receipts/{receiptId} (Firebase-owned) + PDF to Storage
10. Flutter app shows the receipt/confirmation screen once the backend confirms the
    write — exact mechanism (poll vs. a backend-provided push/streaming channel) is
    the open real-time-strategy item noted in § 2.
```

This is the canonical example of the new principle: **the backend is the only thing that knows which system of record to ask, and the client never has to.**

## 7. Component Responsibilities (Summary Table)

| Component | Owns | Never Does |
|---|---|---|
| Flutter App | UI, UX, local cart state, client-side validation | Call Firebase or Surfboard directly, compute final sale totals, store secrets |
| Node/Express Backend | Business rules, aggregation, the *only* path to both systems of record | Persist a duplicate of a Surfboard-owned object |
| Firebase Auth | Identity, session tokens | Merchant/Store business data, authorization decisions |
| Firebase RTDB | Application data only (right column, § 4) | Merchant/Store/Device/Payment/Branding/Tips/Payment Methods |
| Firebase Storage | Binary files (invoice scans, receipt PDFs, product images) | Structured/queryable data |
| Surfboard Payments | Merchant/Store/Device/Payment/Branding/Tips/Payment Methods (left column, § 4) | Inventory or catalog data |
| AI Layer | Extraction + insight generation (advisory) over Firebase-owned data | Auto-commit changes without merchant confirmation, touch Surfboard |

## 8. Design Principles

1. **Mobile-first, single-handed use** — unchanged, see [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md).
2. **Two systems of record, one gatekeeper.** The backend is the only thing that talks to Firebase or Surfboard; the client always goes through it, for both money/stock (as before) and now also merchant/store/device/payment identity (new).
3. **Never duplicate a Surfboard object.** If a Firebase field would duplicate something Surfboard tracks, it's a reference (an ID), not a copy — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle).
4. **AI proposes, humans confirm** — unchanged.
5. **Denormalize Firebase-owned data for read speed** — unchanged, applies only to the application-data half of the schema now (see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).
6. **No local servers, no local databases for the merchant.**

## 9. Scalability

- **Stateless backend** — unchanged.
- **Firebase RTDB scaling** — unchanged in principle, but the data volume Firebase now holds is smaller (application data only), which if anything reduces pressure on RTDB's practical per-instance ceilings compared to the original all-in-Firebase design.
- **Surfboard as a scaling dependency:** every Merchant/Store/Device/Payment read is now a live external API call rather than a local Firebase read. The backend should apply short-lived, in-process caching (not RTDB persistence — see § 4) for read-heavy, slow-changing data (e.g. a Store's payment-methods list) where Surfboard's own API doesn't already cache it, and must handle Surfboard latency/downtime gracefully (timeouts, circuit-breaking) rather than let it block unrelated Firebase-owned reads — see [21_BACKEND_GUIDELINES.md § 9](21_BACKEND_GUIDELINES.md#9-error-handling).
- **Analytics aggregation is precomputed** — unchanged, over Firebase-owned `sales`/`inventory` data only.

## 10. Security

- **Authentication:** unchanged — Firebase Authentication, verified server-side.
- **Authorization:** every controller still checks the authenticated user's `merchantId`/`role` (now a *reference* to a Surfboard Merchant, not a locally-owned record) against the resource being accessed.
- **Firebase Security Rules** remain a second, independent enforcement layer for the application-data half of the schema — see [03_DATABASE_DESIGN.md § 6](03_DATABASE_DESIGN.md#6-security-rules-summary). They have nothing to say about Merchant/Store/Device/Payment data, since that never reaches Firebase at all.
- **Surfboard credentials** (API key/secret, webhook signing secret) live only in backend environment variables, exactly as before — see [15_SURFBOARD_INTEGRATION.md § 2](15_SURFBOARD_INTEGRATION.md#2-authentication-backend--surfboard).
- **Payment data:** unchanged — Surfboard's SDK/APIs handle it; SurfPOS never stores raw card data, and now also never stores a duplicate Payment record (§ 4).

## 11. Offline Strategy

Unchanged in spirit from earlier plans, with one clarification: cached **Product catalog/barcode index** for offline lookup is Firebase-owned data and was never affected by this pass. Checkout still requires connectivity — it now depends on **both** a live Firebase write (Sale) and a live Surfboard call (Payment), so the "no connection" message covers both dependencies, not just one.

## 12. Future Expansion

Unchanged from earlier plans (multi-store, Web back-office, regional Firebase sharding, additional AI features) — none of it is affected by the ownership split, since it was already designed to be additive.

---

**Next:** [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md) if arriving here first, otherwise [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) — the Firebase schema for the right-hand column of § 4.
