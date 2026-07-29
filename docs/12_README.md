# SurfPOS AI

**An AI-powered, mobile-first cloud Point-of-Sale platform for small retailers, built on Surfboard Payments as the system of record for merchant, store, device, and payment identity.**

> Note: this file is maintained at `docs/12_README.md` as part of the numbered documentation set; the repository root [`README.md`](../README.md) is the public-facing copy GitHub renders by default. Keep both in sync when the project structure changes.

---

## Overview

SurfPOS AI lets a small retailer run their entire store from a smartphone: register a business (created directly in Surfboard), manage inventory, scan supplier invoices with AI/OCR, bill customers with barcode scanning, accept payments through Surfboard, issue digital receipts, and see AI-generated business insights — with no dedicated POS hardware, no local server, and no local database to maintain.

Full product context: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md).

## Features

- 🧾 Merchant registration (creates the Merchant + Store directly in Surfboard)
- 🔐 Firebase Authentication (owner + staff roles)
- 📊 Daily dashboard with AI business insights
- 📦 Inventory management with low-stock alerts
- 📷 Camera-based barcode scanning
- 🤖 AI invoice scanner (OCR + Gemini)
- 🛒 Cart & barcode billing
- 💳 Payments, Tips, and Payment Methods via Surfboard
- 🔌 Device management (Surfboard card readers)
- 🎨 Branding configuration (Surfboard checkout surfaces)
- 🧾 Digital, shareable receipts
- 📈 Reports & analytics

Full detail per feature: [05_FEATURES.md](05_FEATURES.md).

## Architecture

```
Flutter (mobile) ──REST (HTTPS)──> Node.js/Express Backend
                                        │
                       ┌────────────────┴────────────────┐
                       ▼                                  ▼
            Repositories (Firebase)          Surfboard Integration Layer
            Inventory · Product ·            Merchant · Store · Device ·
            Sale · Order · Receipt ·         Payment · Branding · Tips ·
            Analytics · Settings ·           Payment Methods
            Supplier · User
```

**Two systems of record, one gatekeeper:** Surfboard owns Merchant/Store/Device/Payment/Branding/Tips/Payment Methods; Firebase owns application data. The backend is the only thing that talks to either — the Flutter app never does. Full architecture: [02_ARCHITECTURE.md](02_ARCHITECTURE.md). Entity definitions: [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md).

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js + Express.js |
| Application data | Firebase Realtime Database |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| AI | OCR + Gemini API |
| Merchant / Store / Device / Payments / Branding / Tips / Payment Methods | Surfboard Payments |

## Folder Structure

```
SurfPOS-AI/
├── docs/          # This documentation system — start here
├── frontend/      # Flutter application
├── backend/       # Node.js + Express API
├── firebase/      # Firebase project config (application data only)
├── scripts/       # Setup, deployment, migration, utility scripts
├── api-testing/   # Postman/Bruno API collections
└── design/        # Figma/branding/UI source material
```

Full annotated tree: [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md).

## Installation & Development

See [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) for full setup instructions.

Quick start:

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
| 01 | [PROJECT_OVERVIEW](01_PROJECT_OVERVIEW.md) | What & why |
| 02 | [ARCHITECTURE](02_ARCHITECTURE.md) | System design, data ownership |
| 03 | [DATABASE_DESIGN](03_DATABASE_DESIGN.md) | Firebase schema (application data only) |
| 04 | [API_DOCUMENTATION](04_API_DOCUMENTATION.md) | Backend API reference |
| 05 | [FEATURES](05_FEATURES.md) | Feature-by-feature spec |
| 06 | [UI_UX_GUIDE](06_UI_UX_GUIDE.md) | Design system |
| 07 | [CODING_RULES](07_CODING_RULES.md) | Coding standards |
| 08 | [ARCHITECTURE_DECISIONS](08_ARCHITECTURE_DECISIONS.md) | ADR log |
| 09 | [PROMPT_HISTORY](09_PROMPT_HISTORY.md) | Claude session log |
| 10 | [TASKS](10_TASKS.md) | Granular task tracker |
| 11 | [CHANGELOG](11_CHANGELOG.md) | Release history |
| 12 | [README](12_README.md) | This file |
| 13 | [CLAUDE_CONTEXT](13_CLAUDE_CONTEXT.md) | Start-here for AI sessions |
| 14 | [DEVELOPER_GUIDE](14_DEVELOPER_GUIDE.md) | Setup & deployment |
| 15 | [SURFBOARD_INTEGRATION](15_SURFBOARD_INTEGRATION.md) | Surfboard integration contract |
| 16 | [AI_MODULE](16_AI_MODULE.md) | OCR + Gemini pipeline |
| 17 | [FOLDER_STRUCTURE](17_FOLDER_STRUCTURE.md) | Directory tree |
| 18 | [CONTRIBUTING](18_CONTRIBUTING.md) | Git workflow & PR process |
| 19 | [SURFBOARD_WORKFLOWS](19_SURFBOARD_WORKFLOWS.md) | Merchant/Store/Device/Payment lifecycles |
| 20 | [DOMAIN_MODEL](20_DOMAIN_MODEL.md) | Core entities & ownership |
| 21 | [BACKEND_GUIDELINES](21_BACKEND_GUIDELINES.md) | Layer responsibilities |
| 22 | [DEVELOPMENT_ROADMAP](22_DEVELOPMENT_ROADMAP.md) | 13-phase implementation order |

## Contributors

- Project owner: Velan ([velan87600@gmail.com](mailto:velan87600@gmail.com))

Contribution guidelines: [18_CONTRIBUTING.md](18_CONTRIBUTING.md).

## License

License to be determined by the project owner and recorded here before public release.
