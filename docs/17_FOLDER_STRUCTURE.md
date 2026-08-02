# 17 — Folder Structure

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** Prerequisite reading: [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md), [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md). Every future addition to the codebase should fit into this tree; if it doesn't, update this file first and explain why (see [07_CODING_RULES.md § 3](07_CODING_RULES.md#3-folder-conventions)).

---

## 1. Repository Root

```
SurfPOS-AI/
├── docs/                     # Project knowledge base — see each file's own README/index
├── frontend/                 # Flutter application
├── backend/                  # Node.js + Express API
├── firebase/                 # Firebase project config (Security Rules, indexes) — application data only
├── scripts/                  # Setup, deployment, migration, and utility scripts
├── api-testing/              # Postman/Bruno API collections
├── design/                   # Figma/branding/UI source material
├── .github/                  # CI workflows, issue/PR templates
├── .vscode/                  # Editor recommendations
├── .gitignore
├── LICENSE                   # Placeholder — license not yet chosen
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── package.json
```

## 2. `frontend/` (Flutter) — Full Tree

```
frontend/
├── android/ ios/ linux/ macos/ windows/ web/   # Platform runners
│
├── assets/
│   ├── images/  icons/  animations/  fonts/  logos/  sounds/
│
├── lib/
│   ├── app/
│   │   ├── routes/          # go_router route definitions
│   │   ├── themes/          # AppTheme — see 06_UI_UX_GUIDE.md
│   │   ├── constants/
│   │   ├── configs/         # Build-flavor/environment config (API base URL) — NO Firebase client config needed; the app has no direct Firebase SDK usage (see 02_ARCHITECTURE.md § 2)
│   │   ├── localization/
│   │   └── app.dart
│   │
│   ├── core/
│   │   ├── services/
│   │   ├── network/         # ApiClient (dio wrapper) — the ONLY network layer; no firebase_database/firebase_auth-direct code paths
│   │   ├── utils/
│   │   ├── helpers/
│   │   ├── storage/         # Local device storage wrappers (offline cache)
│   │   ├── exceptions/
│   │   ├── validators/
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── authentication/    # Firebase Auth sign-in/sign-up only — see 05_FEATURES.md § 2
│   │   ├── merchant/          # Merchant profile + Branding — see 05_FEATURES.md §§ 1, 16
│   │   ├── store/              # Store Capabilities, Payment Methods, Devices — see 05_FEATURES.md §§ 14–15
│   │   ├── dashboard/          # See 05_FEATURES.md § 3
│   │   ├── inventory/          # See 05_FEATURES.md § 4
│   │   ├── barcode/            # See 05_FEATURES.md § 5
│   │   ├── invoice_ai/         # See 05_FEATURES.md § 6, 16_AI_MODULE.md
│   │   ├── billing/             # See 05_FEATURES.md § 7
│   │   ├── cart/                # See 05_FEATURES.md § 8
│   │   ├── payments/            # See 05_FEATURES.md § 9, 15_SURFBOARD_INTEGRATION.md
│   │   ├── receipts/            # See 05_FEATURES.md § 10
│   │   ├── analytics/           # See 05_FEATURES.md §§ 11–12
│   │   ├── settings/            # SurfPOS's own settings only — see 05_FEATURES.md § 13
│   │   └── profile/             # Signed-in user's own account profile
│   │       └── (each feature folder follows the same data/domain/presentation shape once implemented)
│   │
│   └── main.dart
│
├── test/
├── integration_test/
└── pubspec.yaml
```

## 3. `backend/` (Node.js + Express) — Full Tree

```
backend/
├── src/
│   ├── config/                 # Env loading/validation, third-party client config
│   ├── routes/                 # Express route definitions — thin, no logic
│   ├── controllers/            # Request-in/response-out only — see 21_BACKEND_GUIDELINES.md § 2
│   ├── middleware/
│   │   # auth.middleware.js · validate.middleware.js · rateLimit.middleware.js · error.middleware.js
│   ├── services/               # Shared/cross-cutting service logic (not domain-specific)
│   │
│   ├── modules/                 # Domain Services — see 21_BACKEND_GUIDELINES.md §§ 3–4
│   │   ├── auth/                 # Client Authentication (Firebase identity only) — Roadmap Phase 3
│   │   ├── merchant/             # merchant.service.js, merchant.mapper.js — Surfboard-owned, no repository — Roadmap Phases 4–5
│   │   ├── store/                # store.service.js, store.mapper.js — Surfboard-owned (incl. Payment Methods) — Roadmap Phase 6
│   │   ├── inventory/             # inventory.service.js, inventory.repository.js — Firebase-owned — Roadmap Phase 7
│   │   ├── billing/               # billing.service.js, sales.repository.js — Firebase-owned — Roadmap Phase 8
│   │   ├── payments/               # payments.service.js — Surfboard-owned (incl. Tips), webhook handler — Roadmap Phase 9
│   │   ├── device/                 # device.service.js, device.mapper.js — Surfboard-owned — Roadmap Phase 10
│   │   ├── branding/                # branding.service.js, branding.mapper.js — Surfboard-owned — Roadmap Phase 11
│   │   ├── analytics/                # analytics.service.js, analytics.repository.js — Firebase-owned — Roadmap Phase 12
│   │   ├── ai/                        # OCR, OpenRouter, product/supplier matching — Firebase-owned — Roadmap Phase 13
│   │   ├── receipts/                   # receipts.service.js, receipts.repository.js — Firebase-owned
│   │   └── suppliers/                   # suppliers.service.js, suppliers.repository.js — Firebase-owned, new in this pass
│   │
│   ├── integrations/                     # Raw, reusable third-party HTTP client wrappers — no business logic
│   │   └── surfboard/
│   │       ├── surfboardClient.base.js     # Shared request plumbing (client/)
│   │       ├── auth.client.js
│   │       ├── merchant.client.js
│   │       ├── payment.client.js            # Includes Tips — see ADR-016
│   │       ├── store.client.js               # Includes Payment Methods — see ADR-016
│   │       ├── device.client.js
│   │       ├── branding.client.js
│   │       ├── auth/                          # SDK authentication strategy pattern — see ADR-019
│   │       │   ├── authStrategy.js              # AuthStrategy contract + STRATEGY_TYPES
│   │       │   ├── authenticationManager.js      # Strategy selection/orchestration
│   │       │   ├── authConfig.js                  # Fail-fast credential validation per strategy
│   │       │   ├── credentialLoader.js             # Secure credential loading + redaction
│   │       │   └── strategies/                      # apiKeyStrategy.js, bearerTokenStrategy.js, oauthStrategy.js
│   │       ├── provider/                      # tokenProvider.js, tokenRefreshStrategy.js (cache+refresh for token strategies)
│   │       ├── cache/                         # tokenCache.js — TTL cache, single-flight refresh dedup
│   │       └── mappers/                       # Surfboard DTO → domain model (see 21_BACKEND_GUIDELINES.md § 6)
│   │
│   ├── firebase/                # Firebase Admin SDK init only — every read/write goes through a Repository
│   ├── utils/                   # Cross-cutting helpers, incl. the single logger instance
│   ├── constants/                # Single source of truth — see 07_CODING_RULES.md § 2
│   ├── types/                     # JSDoc-only shared type definitions mirroring 20_DOMAIN_MODEL.md
│   ├── validators/                # Request validation schemas, one per resource
│   ├── logs/                       # Local dev log output (gitignored)
│   ├── docs/
│   │   └── swagger/                 # Reserved structure for a future OpenAPI spec — paths/, components/, schemas/
│   ├── app.js
│   └── server.js
│
├── tests/                        # Mirrors src/
├── package.json
└── .env.example
```

### Layer rationale

`routes → controllers → services/modules → { repositories (Firebase) | integration clients (Surfboard) }` — strictly one direction. Full contract: [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md).

### Why `merchant/`, `store/`, `device/`, `branding/` replaced the old single `modules/surfboard/`

Earlier plans had one catch-all `modules/surfboard/` folder for "all Surfboard Payments API calls." Now that Surfboard owns seven distinct entities (Merchant, Store, Device, Payment, Branding, Tips, Payment Methods — see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)), each gets its own Domain Service module like any other domain, calling into the shared `src/integrations/surfboard/` client layer — see [08_ARCHITECTURE_DECISIONS.md § ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split) for the full rationale, including why Tips folded into `payments/` and Payment Methods folded into `store/` rather than getting their own module.

## 4. `firebase/`, `scripts/`, `api-testing/`, `design/`

```
firebase/
├── firebase.json           # Firebase CLI project config
├── database.rules.json     # RTDB Security Rules — application data only, see 03_DATABASE_DESIGN.md § 8
├── indexes.json             # Human-readable .indexOn reference — see 03_DATABASE_DESIGN.md § 7
└── storage.rules

scripts/
├── setup/          # One-time environment/project bootstrap
├── deployment/     # Deploy scripts
├── migration/      # Firebase RTDB data migration scripts
└── utilities/      # Ad hoc operator tools

api-testing/
├── Postman/
└── Bruno/

design/
├── figma/
├── branding/       # SurfPOS's own brand guidelines — distinct from Surfboard Branding (05_FEATURES.md § 16)
├── ui/
└── assets/
```

## 5. Where New Things Go (Quick Reference)

| Adding... | Goes in |
|---|---|
| A new Flutter screen for an existing feature | `frontend/lib/features/<feature>/presentation/` |
| A new Flutter feature entirely | New `frontend/lib/features/<name>/` following the `data/domain/presentation` shape |
| A new shared UI component | `frontend/lib/core/widgets/` |
| A new Firebase-owned backend resource | `routes/`, `controllers/`, and `modules/<name>/{<name>.service.js, <name>.repository.js}`, plus a `validators/` schema |
| A new Surfboard-owned backend resource | `modules/<name>/<name>.service.js` (no repository) + `integrations/surfboard/<name>.client.js` if one doesn't already cover it (check [ADR-016](08_ARCHITECTURE_DECISIONS.md#adr-016--surfboard-domain-module-split) before adding a new client file) |
| A new AI capability | `backend/src/modules/ai/` |
| A new Firebase schema node/field | Document it in [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) **before** writing the code — and first check it isn't actually a Surfboard-owned field (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)) |
| A new third-party integration (non-Surfboard) | Its own `backend/src/integrations/<provider>/` following the same client/mapper shape |
| A new Firebase Security Rule | `firebase/database.rules.json` or `firebase/storage.rules` |

---

**Next:** [18_CONTRIBUTING.md](18_CONTRIBUTING.md) — Git workflow and PR process for working within this structure.
