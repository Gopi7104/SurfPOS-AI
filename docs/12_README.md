# SurfPOS AI

**An AI-powered, mobile-first cloud Point-of-Sale platform for small retailers, fully integrated with Surfboard Payments.**

> Note: this file is maintained at `docs/12_README.md` as part of the documentation set; copy/symlink it to the repository root as `README.md` once the codebase is scaffolded (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).

---

## Overview

SurfPOS AI lets a small retailer run their entire store from a smartphone: register a business, manage inventory, scan supplier invoices with AI/OCR, bill customers with barcode scanning, accept payments through Surfboard Payments, issue digital receipts, and see AI-generated business insights — with no dedicated POS hardware, no local server, and no local database to maintain.

Full product context: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md).

## Features

- 🧾 Merchant self-serve registration & onboarding
- 🔐 Firebase Authentication (owner + staff roles)
- 📊 Daily dashboard with AI business insights
- 📦 Inventory management with low-stock alerts
- 📷 Camera-based barcode scanning (no external hardware)
- 🤖 AI invoice scanner (OCR + Gemini) — photograph a supplier invoice, get structured line items matched to your catalog
- 🛒 Cart & barcode billing
- 💳 Payments via Surfboard Payments (card / UPI / wallet)
- 🧾 Digital, shareable receipts
- 📈 Reports & analytics

Full detail per feature: [05_FEATURES.md](05_FEATURES.md).

## Architecture

```
Flutter (mobile) ──Firebase SDKs──> Firebase (Auth · Realtime DB · Storage)
       │
       └──REST (HTTPS)──> Node.js/Express Backend ──> Gemini API / OCR
                                                   └──> Surfboard Payments
```

Full architecture, data flow, and security model: [02_ARCHITECTURE.md](02_ARCHITECTURE.md).

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js + Express.js |
| Database | Firebase Realtime Database |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| AI | OCR + Gemini API |
| Payments | Surfboard Payments |

## Folder Structure

```
surfpos-ai/
├── docs/          # This documentation system — start here
├── mobile/        # Flutter application
└── backend/       # Node.js + Express API
```

Full annotated tree: [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md).

## Installation & Development

See [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) for full setup instructions (Flutter setup, Node setup, Firebase project setup, environment variables, running frontend/backend, deployment, debugging).

Quick start (once the codebase is scaffolded per [10_TASKS.md](10_TASKS.md) Phase 0):

```bash
# Backend
cd backend
npm install
npm run dev

# Mobile
cd mobile
flutter pub get
flutter run
```

## Documentation Index

| # | File | Purpose |
|---|---|---|
| 01 | [PROJECT_OVERVIEW](01_PROJECT_OVERVIEW.md) | What & why |
| 02 | [ARCHITECTURE](02_ARCHITECTURE.md) | System design |
| 03 | [DATABASE_DESIGN](03_DATABASE_DESIGN.md) | Firebase schema |
| 04 | [API_DOCUMENTATION](04_API_DOCUMENTATION.md) | Backend API reference |
| 05 | [FEATURES](05_FEATURES.md) | Feature-by-feature spec |
| 06 | [UI_UX_GUIDE](06_UI_UX_GUIDE.md) | Design system |
| 07 | [CODING_RULES](07_CODING_RULES.md) | Coding standards |
| 08 | [ARCHITECTURE_DECISIONS](08_ARCHITECTURE_DECISIONS.md) | ADR log |
| 09 | [PROMPT_HISTORY](09_PROMPT_HISTORY.md) | Claude session log |
| 10 | [TASKS](10_TASKS.md) | Roadmap |
| 11 | [CHANGELOG](11_CHANGELOG.md) | Release history |
| 12 | [README](12_README.md) | This file |
| 13 | [CLAUDE_CONTEXT](13_CLAUDE_CONTEXT.md) | Start-here for AI sessions |
| 14 | [DEVELOPER_GUIDE](14_DEVELOPER_GUIDE.md) | Setup & deployment |
| 15 | [SURFBOARD_INTEGRATION](15_SURFBOARD_INTEGRATION.md) | Payments integration |
| 16 | [AI_MODULE](16_AI_MODULE.md) | OCR + Gemini pipeline |
| 17 | [FOLDER_STRUCTURE](17_FOLDER_STRUCTURE.md) | Directory tree |
| 18 | [CONTRIBUTING](18_CONTRIBUTING.md) | Git workflow & PR process |

## Contributors

- Project owner: Velan ([velan87600@gmail.com](mailto:velan87600@gmail.com))

Contribution guidelines: [18_CONTRIBUTING.md](18_CONTRIBUTING.md).

## License

License to be determined by the project owner and recorded here before public release.
