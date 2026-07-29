# 02 — Architecture

> Prerequisite reading: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md). Related: [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md), [16_AI_MODULE.md](16_AI_MODULE.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md).

---

## 1. System Architecture (High Level)

SurfPOS AI is a **client-server, cloud-native, multi-tenant** system. "Tenant" = merchant. Every merchant's data is logically isolated by `merchantId` even though it lives in a single shared Firebase Realtime Database.

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (Mobile)                     │
│  Auth UI · Dashboard · Inventory · Scanner · Billing · Reports   │
└───────────────┬───────────────────────────────┬─────────────────┘
                │ Firebase SDKs (direct)         │ REST (HTTPS/JSON)
                │ - Auth                         │
                │ - Realtime DB (read-heavy,     │
                │   real-time listeners)         │
                │ - Storage (uploads)            │
                ▼                                ▼
   ┌─────────────────────────┐      ┌───────────────────────────────┐
   │   FIREBASE PLATFORM     │      │   NODE.JS + EXPRESS BACKEND    │
   │  - Authentication       │◄────►│  - Business logic / validation │
   │  - Realtime Database    │      │  - Firebase Admin SDK          │
   │  - Storage              │      │  - AI orchestration            │
   └─────────────────────────┘      │  - Surfboard Payments client   │
                                     │  - Analytics aggregation       │
                                     └───────────┬─────────────────┬─┘
                                                  │                 │
                                                  ▼                 ▼
                                     ┌────────────────────┐  ┌───────────────────┐
                                     │   AI LAYER          │  │ SURFBOARD PAYMENTS │
                                     │  - OCR engine       │  │  - Merchant API    │
                                     │  - Gemini API       │  │  - Payments API    │
                                     └────────────────────┘  │  - Device API      │
                                                              └───────────────────┘
```

### Why a hybrid client (direct-to-Firebase *and* through the backend)?

- **Direct-to-Firebase** is used for everything that benefits from real-time sync and low latency and does **not** require server-side business logic or a secret: reading products, listening to inventory changes, listening to sale status, reading the merchant's own settings.
- **Through the backend** is required whenever the operation must (a) call a third-party service that needs a secret key (Surfboard Payments, Gemini API, OCR), (b) enforce business rules that must not be trusted to the client (e.g. "don't let a sale total be forged," "verify a payment before marking a sale complete"), or (c) perform aggregation too heavy for the client (analytics rollups).

This is a deliberate hybrid, not an accident — see [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).

---

## 2. Frontend (Flutter)

- **Pattern:** Feature-first modules, each internally split into `data / domain / presentation` (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).
- **State management:** Riverpod (recommended default — see [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) for rationale and how to revisit this).
- **Navigation:** `go_router` for declarative, deep-link-friendly routing.
- **Network layer:** A single `ApiClient` wrapper around `dio` for all backend REST calls (auth token attached automatically via interceptor). Firebase SDKs (`firebase_auth`, `firebase_database`, `firebase_storage`) are used directly for their respective concerns.
- **Responsibilities:**
  - Render UI, capture user input, run client-side validation (fast feedback only — never the source of truth).
  - Maintain real-time listeners on Firebase RTDB for live inventory/sales/dashboard updates.
  - Call the backend for anything that touches AI, payments, or aggregated analytics.
  - Cache the minimum data needed for the offline strategy (see §9).

## 3. Backend (Node.js + Express)

- **Pattern:** Layered — `routes → controllers → services → firebase/external clients`. See [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) for the exact tree.
- **Responsibilities:**
  - Verify every incoming request's Firebase ID token (`auth.middleware.js`) using the Firebase Admin SDK.
  - Own all business logic that must not run on the client: sale totals/tax computation validation, inventory decrement on sale, payment confirmation, invoice-to-inventory reconciliation, analytics aggregation.
  - Orchestrate the AI layer (OCR → Gemini structuring → product matching).
  - Orchestrate Surfboard Payments (merchant onboarding, payment intents, webhook handling).
  - Never store secrets or service credentials on the client. Every third-party secret (Gemini API key, Surfboard API keys, Firebase service account) lives only in backend environment variables.
- **The backend does not maintain its own primary datastore.** It reads/writes Firebase Realtime Database via the Admin SDK. There is no separate SQL/NoSQL database to keep in sync — Firebase RTDB is the single source of truth for both client and server.

## 4. Firebase (Platform Layer)

| Firebase Product | Role |
|---|---|
| **Authentication** | Identity for merchants and staff. Issues ID tokens the backend verifies. |
| **Realtime Database** | Single source of truth for all application data (see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)). |
| **Storage** | Binary assets: product photos, invoice scan images, generated receipt PDFs. |
| **Security Rules** | Enforce that a user can only read/write data scoped to their own `merchantId` / `storeId`, as a second line of defense behind backend validation. |

Firebase is intentionally the **entire data platform** for this project (no separate SQL database) — this keeps operational overhead near zero for a small-retailer-focused product. Trade-offs of this choice are recorded in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).

## 5. AI Layer

Two distinct AI responsibilities (full detail in [16_AI_MODULE.md](16_AI_MODULE.md)):

1. **OCR** — converts a photographed supplier invoice (image) into raw text, and reads barcodes when the built-in barcode scanner falls back to text-based lookup.
2. **Gemini API** — takes the raw OCR text and:
   - Structures it into line items (`{name, quantity, unitPrice}`).
   - Matches extracted items against the merchant's existing product catalog (fuzzy match + confidence score).
   - Generates business insights from aggregated sales data (e.g. "Product X sales dropped 30% this week", reorder suggestions).

The AI layer is invoked **only from the backend** — never directly from the Flutter app — so API keys stay server-side and so extracted data can be validated/sanitized before being written to the database.

## 6. Surfboard Payments Layer

Full detail in [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md). Summary of responsibilities:

- Merchant onboarding/KYC handoff during registration.
- Creating a payment intent/charge when a sale is checked out.
- Receiving webhook callbacks on payment success/failure and reconciling that with the `sales`/`payments` nodes.
- Managing any physical card-reader **device** linkage, if the merchant uses one (optional; the phone itself is the primary terminal for tap-to-pay/UPI/QR flows where supported).

All Surfboard API calls are made **server-side only**, since they require a secret API key.

## 7. Data Flow (Example: A Sale)

```
1. Cashier scans/searches products in Flutter app → builds cart (local state).
2. Cashier taps "Checkout" → app sends cart to backend: POST /api/v1/sales
3. Backend validates cart against live product prices in Firebase RTDB
   (never trusts client-submitted prices/totals).
4. Backend creates a Surfboard payment intent for the validated total.
5. App collects payment via Surfboard SDK/device flow.
6. Surfboard sends a webhook to backend confirming payment status.
7. Backend, on confirmed payment:
     a. Writes the `sales/{storeId}/{saleId}` record (status: completed)
     b. Decrements `inventory/{storeId}/{productId}` quantities
     c. Writes `payments/{paymentId}`
     d. Generates a receipt → writes `receipts/{receiptId}` (+ PDF to Storage)
8. Flutter app, listening on the sale node in real time, shows the
   receipt/confirmation screen the instant the backend writes it.
```

This flow is the canonical example of "client does UI + real-time listening, backend owns the source of truth for money and stock."

## 8. Component Responsibilities (Summary Table)

| Component | Owns | Never Does |
|---|---|---|
| Flutter App | UI, UX, local cart state, client-side validation, real-time display | Compute final sale totals as source of truth, call Surfboard/Gemini directly, store secrets |
| Node/Express Backend | Business rules, third-party orchestration, aggregation, security-critical writes | Hold a duplicate database, serve UI |
| Firebase Auth | Identity, session tokens | Authorization decisions (that's Security Rules + backend) |
| Firebase RTDB | Canonical data storage, real-time sync to clients | Complex relational queries (data is denormalized instead) |
| Firebase Storage | Binary files | Structured/queryable data |
| AI Layer | Extraction + insight generation (advisory) | Auto-commit changes without merchant confirmation for low-confidence extractions |
| Surfboard Payments | Payment processing, settlement | Inventory or catalog data |

## 9. Design Principles

1. **Mobile-first, single-handed use.** Every primary screen must be usable one-handed on a phone at a checkout counter.
2. **Backend is the source of truth for money and stock.** The client can display optimistic UI, but final sale/payment/inventory state is always backend-validated.
3. **AI proposes, humans confirm (for anything that changes stock or money).** Invoice scan results are a draft the merchant reviews before committing to inventory.
4. **Denormalize for read speed.** Firebase RTDB has no joins — data is intentionally duplicated/flattened where it improves read performance (see [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md)).
5. **Multi-tenant by `merchantId` from day one**, even though multi-store UI is Phase 2+, so no migration is needed later.
6. **No local servers, no local databases for the merchant.** Everything the merchant needs is available from any device, anywhere.

## 10. Scalability

- **Stateless backend:** The Express API holds no in-memory session state, so it can be horizontally scaled behind a load balancer / run as multiple container instances or serverless functions.
- **Firebase RTDB scaling:** RTDB scales well for read-heavy, moderately-sized trees, but a single RTDB instance has practical size/throughput ceilings. The data model shards data under `merchantId`/`storeId` subtrees specifically so that, if a single RTDB instance becomes a bottleneck, merchants can eventually be split across multiple RTDB instances (regional or shard-based) with minimal schema change — see [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).
- **Analytics aggregation is precomputed**, not computed live on every dashboard load — a scheduled job (cron or Cloud Function) rolls up raw `sales` data into `analytics/{storeId}/{period}` nodes, so dashboard reads stay O(1)-ish regardless of historical data volume.
- **AI calls are async where possible.** Invoice scanning is a background job with a status field (`pending → processing → ready_for_review`), not a blocking request, so the app stays responsive on slow AI responses.

## 11. Security

- **Authentication:** Firebase Authentication issues ID tokens; every backend request is authenticated by verifying that token server-side (`auth.middleware.js`).
- **Authorization:** Enforced twice —
  1. **Backend:** every controller checks the authenticated user's `merchantId`/`role` against the resource being accessed before performing the action.
  2. **Firebase Security Rules:** a second, independent layer of protection for any direct client reads/writes to RTDB/Storage, scoped by `merchantId`/`storeId`/`uid`.
- **Secrets:** Gemini API key, Surfboard API keys, and the Firebase service account credentials live only in backend environment variables (see [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md)) — never bundled into the Flutter app.
- **Payment data:** Card/payment details are handled entirely by Surfboard's SDK/APIs; SurfPOS AI never stores raw card data (PCI scope stays with Surfboard).
- **Input validation:** All backend endpoints validate request bodies against schemas before touching the database (see [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md), [07_CODING_RULES.md](07_CODING_RULES.md)).

## 12. Offline Strategy

Small retailers frequently deal with unreliable connectivity. The offline approach for the initial build vs. future scope:

**Phase 1 (initial build):**
- The **product catalog and barcode index** are cached locally on the device after first load, so barcode lookup and product search work offline.
- Billing/cart building works offline (cart is local state regardless of connectivity).
- **Checkout requires connectivity** in Phase 1, because payment processing (Surfboard) and sale-of-record writes are backend/network-dependent. The app should clearly surface "no connection — cannot complete payment" rather than silently failing.
- Dashboard/analytics require connectivity (they read from Firebase/backend).

**Future (see [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) and [01_PROJECT_OVERVIEW.md § Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope)):**
- Queue completed offline sales locally and sync + reconcile with the backend (and, where supported, Surfboard's offline/deferred payment capture) once connectivity returns.
- Local-first inventory decrement with conflict resolution on reconnect.

## 13. Future Expansion

See [01_PROJECT_OVERVIEW.md § Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope) for the product-level list. Architecturally, the system is already shaped to support these without a rewrite:

- **Multi-store:** the schema already keys inventory/sales by `storeId` under a `merchantId`; multi-store UI is additive.
- **Web back-office:** the backend is a plain REST API, consumable by a future Flutter Web or React admin panel with no backend changes.
- **Sharding Firebase by region/merchant tier:** possible because all data is already partitioned by `merchantId`.
- **Additional AI features:** the AI layer is isolated behind `ai.service.js` (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)), so new models/providers can be added without touching controllers.

---

**Next:** [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) — full Firebase Realtime Database schema.
