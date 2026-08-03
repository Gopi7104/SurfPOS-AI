# Session Log — "phase3"

**Dates covered:** 2026-07-29 – 2026-07-30
**Branch:** `gopi`
**Scope:** Backend Roadmap Phases 3–7 (Surfboard SDK auth layer extension, Application Client Authentication, Merchant Creation, Merchant Functions, Store Capabilities, Inventory Management), followed by a real Firebase infrastructure connection pass.

This log is a curated summary of a long multi-phase working session, not a raw transcript. Full detail for each phase lives in `docs/09_PROMPT_HISTORY.md` (the authoritative "why") and `docs/11_CHANGELOG.md` (the authoritative "what"); this file is a single, chronological narrative tying them together.

---

## 1. Surfboard SDK Authentication Layer (extends Phase 2, not Roadmap Phase 3)

**Ask:** Implement a pluggable Surfboard authentication layer (API Key / Bearer / OAuth) using a strategy pattern, without hardcoding the auth flow.

**Key finding before writing code:** the docs' actual Roadmap "Phase 3" is Firebase *application* identity, not Surfboard SDK auth — a naming collision with the user's request. Proceeded with the Surfboard work anyway, documenting it as an extension of Phase 2 (task 2.6) rather than claiming the Phase 3 slot.

**Built:**
- `integrations/surfboard/auth/` — `authStrategy.js` (contract + `STRATEGY_TYPES`), `authenticationManager.js`, `authConfig.js`, `credentialLoader.js`, `strategies/{apiKeyStrategy,bearerTokenStrategy,oauthStrategy}.js`
- `integrations/surfboard/provider/tokenProvider.js` + `tokenRefreshStrategy.js`, `integrations/surfboard/cache/tokenCache.js`
- `middleware/authentication.middleware.js` replacing the old `auth.middleware.js` placeholder
- 27 new tests

**Recorded as:** ADR-019.

---

## 2. Phase 3 — Application Client Authentication (email/password)

**Ask (after clarifying the naming collision above):** Firebase identity for SurfPOS users — sign-up, sign-in, `GET /auth/me`, sign-out, auth middleware. Explicitly not merchant/Surfboard auth.

**Built:**
- `modules/auth/{auth.service,users.repository}.js`
- `POST /auth/signup`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/me`
- `middleware/auth.middleware.js` refactored to a DI factory sharing token verification with the login flow

**Notable debugging:** a route-level Supertest suite that tried to `vi.mock()` `firebase/admin.js` didn't work — the mock never intercepted a nested `require()` call in this project's Vitest/CJS setup. Resolved by making route-level tests wiring/validation smoke tests only, and putting full business-logic coverage in service-level tests against constructor-injected fakes.

**Recorded as:** ADR-020. Phone/OTP sign-in and staff-invite (task 3.3) were left out of scope.

---

## 3. Phase 4 — Merchant Creation (re-scoped to application tracking)

**Ask:** Create and track a merchant application via the Surfboard SDK — explicitly *not* the originally-documented `POST /auth/register` (Firebase + Merchant + Store in one call). No Store creation, no `users/{uid}.merchantId` write.

**Built:**
- `merchant.client.js#createMerchant()` + `mappers/merchant.mapper.js` (completing a Phase 2 placeholder)
- `modules/merchant/{merchantApplication.service,merchantApplication.repository}.js`
- `POST/GET /merchant/applications`, `GET /merchant/applications/:id`
- New Firebase-owned node `merchantApplications/{uid}`

**Real bug found and fixed:** `SurfboardBaseClient` eagerly built an `AuthenticationManager` in its constructor (which validates credentials) — harmless until this phase became the first code to wire a Surfboard domain client into `app.js`, at which point it crashed the whole app on boot without `SURFBOARD_API_KEY` set. Fixed with a lazy getter, matching `firebase/admin.js`'s existing lazy-init pattern.

**Recorded as:** ADR-021.

---

## 4. Phase 5 — Merchant Functions

**Ask:** `GET`/`PATCH` merchant profile + status, caller-scoped (no `:merchantId` param).

**Problem to solve:** Phase 4 never wrote `users/{uid}.merchantId`, so there was no obvious way to resolve which merchant a caller belongs to. Solved by resolving `merchantId` from the caller's own `merchantApplications/{uid}.merchantId` instead.

**Built:**
- `merchant.client.js#getMerchant()`/`#updateMerchant()`, mapper additions (`toMerchantProfile`/`toMerchantUpdateWire`)
- `modules/merchant/{merchant.service,merchant.repository}.js` — `merchant.repository.js` deliberately composes `merchantApplication.repository.js` rather than touching Firebase directly, since both would otherwise own the same node
- `GET/PATCH /merchant`, `GET /merchant/status` (the latter is a normalized view over `getMerchant()` — no separate Surfboard status endpoint was assumed to exist)

**Recorded as:** ADR-022.

---

## 5. Phase 6 — Store Capabilities

**Ask:** Store CRUD (`POST/GET /stores`, `GET/PATCH /stores/:storeId`), no invented Surfboard endpoints/payloads.

**Problem to solve:** no confirmed Surfboard "list stores by merchant" endpoint, and the same "no `users/{uid}` reference" problem as Phase 5.

**Built:**
- `store.client.js#createStore()`/`#getStore()`/`#updateStore()` + `mappers/store.mapper.js`
- `modules/store/{store.service,store.repository}.js`
- New Firebase-owned registry `storeReferences/{uid}/{storeId}` — SurfPOS's own record of which storeIds it created, since no list-by-merchant Surfboard call is assumed. `GET /stores` reads this registry and hydrates each entry live.
- `merchant.service.js` gained a `getMerchantId()` export so `store.service.js` could resolve `merchantId` via a cross-module Service call rather than reaching into `merchant.repository.js` directly.

**Recorded as:** ADR-023.

---

## 6. Phase 7 — Inventory Management

**Ask:** Product catalog CRUD (categories, barcode, SKU, supplier, price, cost, tax, unit, minimum stock, status) + per-store stock, with search/filter/pagination/soft-delete. Entirely Firebase-owned, zero Surfboard calls.

**Built:**
- `modules/inventory/{inventory.service,product.repository,stock.repository}.js`
- `POST/GET /inventory/products`, `GET/PATCH/DELETE /inventory/products/:productId`, `PATCH /inventory/products/:productId/stock`
- Search/filter/pagination done in-memory over the merchant's catalog (a documented simplification for small-retailer catalog sizes)
- Stock adjustment is transactional (extending the worked example already in `21_BACKEND_GUIDELINES.md § 4`), upserts a store's first stock record on initial restock, and aborts via a new `InsufficientStockError` rather than ever letting quantity go negative
- `supplierId` added as a new optional Product field, referencing the already-documented-but-unbuilt Supplier entity (task 7.4, still open)

**Recorded as:** ADR-024. This was the first phase with zero Surfboard involvement.

**Cumulative test count after Phase 7: 233 backend tests, all passing.**

---

## 7. Firebase Infrastructure Connection

**Ask:** Connect Firebase end-to-end to both the Flutter frontend and the Express backend — no business features, no changes to Merchant/Store/Inventory/Billing/Surfboard SDK.

**Starting state:** no `google-services.json`, no backend service-account credentials, no Firebase CLI in this environment — asked the user how to proceed rather than guessing.

**The user provided a real service-account JSON** for project `surfpos-ai`, placed in `backend/src/config/`. From there:

1. **Fixed a real security gap immediately:** `.gitignore`'s Firebase service-account pattern (`firebase-adminsdk-*.json`) didn't match Firebase Console's real filename convention (`<project-id>-firebase-adminsdk-<hash>.json` — the string is in the middle, not the start), leaving the downloaded key unprotected from being committed. Broadened to `*firebase-adminsdk*.json`, plus added `google-services.json`/`GoogleService-Info.plist`.
2. Extracted the credentials into `backend/.env` (gitignored) and deleted the raw JSON file — no reason to keep the same secret in two places.
3. **Found and fixed two real, previously-invisible bugs** once real credentials were actually exercised for the first time:
   - **`firebase-admin` v13+ modular API migration.** The installed `firebase-admin@^14.2.0` no longer has `admin.credential.cert()` or `app.auth()`/`app.database()`/`app.storage()` — `firebase/admin.js` was written against the pre-v13 shape. Fixed to `admin.cert()` + `getAuth(app)`/`getDatabase(app)`/`getStorage(app)` from the `firebase-admin/{auth,database,storage}` subpaths.
   - **Test/production credential isolation gap.** `config/index.js` loaded `.env` unconditionally regardless of `NODE_ENV`, so `npm test` loaded real credentials the moment they existed. One route-level "Firebase unconfigured in this env" smoke test actually **created a real user in the live Firebase project** before this was caught. Fixed by loading `.env.test` (absent by default, so nothing loads) whenever `NODE_ENV=test`. The stray user (`owner@example.com`) was found via `getUserByEmail` and deleted, with the user's explicit confirmation first.
4. Hardened `firebase/admin.js` so Auth, Realtime Database, and Storage validate independently (Auth only needs the service-account identity; RTDB/Storage each additionally need their own URL/bucket), instead of one all-or-nothing gate.
5. Added `backend/scripts/verifyFirebaseConnection.js` (`npm run verify:firebase`) — an operator tool that exercises Auth (`listUsers`), RTDB (read/write round-trip), and Storage (bucket existence) independently and reports pass/fail per service. Fixed one more bug in this script itself: it never exited, because RTDB holds a persistent connection open — added an explicit `process.exit()`.
6. Frontend: added `firebase_core`/`firebase_auth` to `pubspec.yaml` (deliberately not `firebase_database`/`firebase_storage` — the app only ever talks to those through the backend), wired `Firebase.initializeApp()` into `main.dart` (no UI changes, no generated `FirebaseOptions`), and registered the `google-services` Gradle plugin in `android/settings.gradle.kts` + `android/app/build.gradle.kts`.
7. Ran `flutter build apk --debug` to honestly verify current state — it fails cleanly at the `google-services` Gradle plugin step with a specific "file is missing" error, confirming the wiring itself is correct and the only blocker is the absent `google-services.json`.

**Final verified state (`npm run verify:firebase`):**
```
✓ Auth: listUsers() succeeded — service-account credentials are valid
✓ Realtime Database: read/write round-trip succeeded
✗ Storage: not configured — deliberately deferred by explicit user instruction, not a gap
```

Auth and Realtime Database are genuinely connected and live-verified against the real `surfpos-ai` project. Storage stays unconfigured until a feature actually needs it (Receipts/AI invoice images).

**Recorded as:** ADR-025.

**Still blocking full frontend verification:** a real `google-services.json` for an Android app registered in the `surfpos-ai` Firebase project. The session ended mid-way through resolving this — the user confirmed they're registering a new Android app now, and the placeholder `applicationId`/`namespace` (`com.example.surfpos_ai`) was flagged as worth replacing with a real package name before registering, rather than keeping the Flutter template default long-term.

---

## Outstanding / Next Steps

- Provide a real `google-services.json` (Android) — package name should match whatever `applicationId` this project ends up using.
- Decide on a real Android `applicationId` (currently the placeholder `com.example.surfpos_ai`).
- Phase 8 (Billing) is next in roadmap order — **not started, pending explicit approval**, per this session's own scoping instructions on every phase.
- Still open, carried across every phase in this session: Surfboard sandbox credentials + official API docs (every `merchant.client.js`/`store.client.js` wire format is still an educated guess, isolated to mapper files specifically so confirming it later is a small change), Gemini API key, phone/OTP sign-in, staff-invite flow, Supplier CRUD, Payment Methods, the original `POST /auth/register` single-call orchestration (deferred, not deleted).

## Architecture Decision Records added this session

ADR-019 through ADR-025 — see `docs/08_ARCHITECTURE_DECISIONS.md` for full detail on each.
