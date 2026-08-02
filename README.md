# SurfPOS AI

**An AI-powered, mobile-first cloud Point-of-Sale platform for small retailers, fully integrated with Surfboard Payments.**

> **Status:** backend Roadmap Phases 1–7 implemented (Surfboard SDK, application auth, merchant application tracking, merchant/store/inventory management); Firebase is now connected end-to-end for Authentication **and Realtime Database** (backend Admin SDK + Flutter client both live-verified against a real project — see `backend/npm run verify:firebase`). Storage is deliberately deferred until a feature needs it. See [docs/13_CLAUDE_CONTEXT.md](docs/13_CLAUDE_CONTEXT.md) for current status and [docs/22_DEVELOPMENT_ROADMAP.md](docs/22_DEVELOPMENT_ROADMAP.md) for the roadmap.

---

## Overview

SurfPOS AI lets a small retailer run their entire store from a smartphone: register a business, manage inventory, scan supplier invoices with AI/OCR, bill customers with barcode scanning, accept payments through Surfboard Payments, issue digital receipts, and see AI-generated business insights — with no dedicated POS hardware, no local server, and no local database to maintain.

Full product context: [docs/01_PROJECT_OVERVIEW.md](docs/01_PROJECT_OVERVIEW.md).

## Features

- 🧾 Merchant registration (creates the Merchant + Store directly in Surfboard)
- 🔐 Firebase Authentication (owner + staff roles)
- 📊 Daily dashboard with AI business insights
- 📦 Inventory management with low-stock alerts
- 📷 Camera-based barcode scanning (no external hardware)
- 🤖 AI invoice scanner (OCR + OpenRouter)
- 🛒 Cart & barcode billing
- 💳 Payments, Tips, and Payment Methods via Surfboard
- 🔌 Device management (Surfboard card readers)
- 🎨 Branding configuration (Surfboard checkout surfaces)
- 🧾 Digital, shareable receipts
- 📈 Reports & analytics

Full detail per feature: [docs/05_FEATURES.md](docs/05_FEATURES.md).

## Architecture

```
Flutter (mobile) ──REST (HTTPS)──> Node.js/Express Backend
                                        │
                       ┌────────────────┴────────────────┐
                       ▼                                  ▼
            Repositories (Firebase)          Surfboard Integration Layer
            Inventory · Product ·            Merchant · Store · Device ·
            Sale · Order · Receipt ·         Payment · Branding · Tips ·
            Analytics · Settings             Payment Methods
```

**Two systems of record, one gatekeeper:** Surfboard owns Merchant/Store/Device/Payment/Branding/Tips/Payment Methods; Firebase owns application data. The backend is the only thing that talks to either. Full architecture: [docs/02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md). Entity definitions: [docs/20_DOMAIN_MODEL.md](docs/20_DOMAIN_MODEL.md).

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js + Express.js |
| Application data | Firebase Realtime Database |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| AI | OpenRouter API + OCR |
| Merchant / Store / Device / Payments / Branding / Tips / Payment Methods | Surfboard Payments |

## Repository Structure

```
SurfPOS-AI/
├── docs/            # Project knowledge base — start here
├── frontend/        # Flutter application
├── backend/         # Node.js + Express API
├── firebase/         # Firebase project config (Security Rules, indexes)
├── scripts/         # Setup, deployment, migration, and utility scripts
├── api-testing/     # Postman/Bruno API collections
├── design/          # Figma/branding/UI source material
├── .github/         # CI workflows, issue/PR templates
└── .vscode/         # Editor recommendations
```

Full annotated tree: [docs/17_FOLDER_STRUCTURE.md](docs/17_FOLDER_STRUCTURE.md).

## Installation & Development

See [docs/14_DEVELOPER_GUIDE.md](docs/14_DEVELOPER_GUIDE.md) for full setup instructions.

```bash
# Backend
cd backend
npm install
npm run dev

# Frontend
cd frontend
flutter pub get
flutter run
```

## Documentation Index

| # | File | Purpose |
|---|---|---|
| 01 | [PROJECT_OVERVIEW](docs/01_PROJECT_OVERVIEW.md) | What & why |
| 02 | [ARCHITECTURE](docs/02_ARCHITECTURE.md) | System design |
| 03 | [DATABASE_DESIGN](docs/03_DATABASE_DESIGN.md) | Firebase schema |
| 04 | [API_DOCUMENTATION](docs/04_API_DOCUMENTATION.md) | Backend API reference |
| 05 | [FEATURES](docs/05_FEATURES.md) | Feature-by-feature spec |
| 06 | [UI_UX_GUIDE](docs/06_UI_UX_GUIDE.md) | Design system |
| 07 | [CODING_RULES](docs/07_CODING_RULES.md) | Coding standards |
| 08 | [ARCHITECTURE_DECISIONS](docs/08_ARCHITECTURE_DECISIONS.md) | ADR log |
| 09 | [PROMPT_HISTORY](docs/09_PROMPT_HISTORY.md) | Claude session log |
| 10 | [TASKS](docs/10_TASKS.md) | Roadmap |
| 11 | [CHANGELOG](docs/11_CHANGELOG.md) | Release history |
| 12 | [README (docs copy)](docs/12_README.md) | Mirrors this file |
| 13 | [CLAUDE_CONTEXT](docs/13_CLAUDE_CONTEXT.md) | Start-here for AI sessions |
| 14 | [DEVELOPER_GUIDE](docs/14_DEVELOPER_GUIDE.md) | Setup & deployment |
| 15 | [SURFBOARD_INTEGRATION](docs/15_SURFBOARD_INTEGRATION.md) | Surfboard integration contract |
| 16 | [AI_MODULE](docs/16_AI_MODULE.md) | OCR + OpenRouter pipeline |
| 17 | [FOLDER_STRUCTURE](docs/17_FOLDER_STRUCTURE.md) | Directory tree |
| 18 | [CONTRIBUTING (full guide)](docs/18_CONTRIBUTING.md) | Git workflow & PR process |
| 19 | [SURFBOARD_WORKFLOWS](docs/19_SURFBOARD_WORKFLOWS.md) | Merchant/Store/Device/Payment lifecycles |
| 20 | [DOMAIN_MODEL](docs/20_DOMAIN_MODEL.md) | Core entities & ownership |
| 21 | [BACKEND_GUIDELINES](docs/21_BACKEND_GUIDELINES.md) | Layer responsibilities |
| 22 | [DEVELOPMENT_ROADMAP](docs/22_DEVELOPMENT_ROADMAP.md) | 13-phase implementation order |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) (pointer to the full guide at [docs/18_CONTRIBUTING.md](docs/18_CONTRIBUTING.md)).

## Contributors

- Project owner: Velan ([velan87600@gmail.com](mailto:velan87600@gmail.com))

## License

Not yet chosen — see [LICENSE](LICENSE). All rights reserved until the project owner selects and records a license.
