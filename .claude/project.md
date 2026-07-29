# SurfPOS AI — Project Reference

> **This is the first file any Claude Code session should read in this repository.** It is the entry point into the project's persistent knowledge base. Read it fully before touching source code, then continue in the order given at the bottom of this file.

---

## Project Name

**SurfPOS AI**

## Project Vision

A small retailer should be able to run their entire store — inventory, billing, payments, and business insight — from a single smartphone, with zero local infrastructure and zero manual data entry from supplier invoices.

## Project Goal

Ship a mobile-first, AI-powered cloud Point-of-Sale platform, fully integrated with **Surfboard Payments**, that lets a small retailer register, stock, sell, get paid, and understand their business — all from one app, with no dedicated POS hardware and no local server or database to maintain.

## Business Problem

Small retailers are underserved by the current POS market:

- Traditional POS software requires dedicated hardware and local IT/backup responsibility.
- Existing cloud POS products are priced and scoped for mid-size/enterprise retail.
- Supplier invoice reconciliation is manual, slow, and error-prone (hand-copying paper invoices into a spreadsheet or POS).
- Payments and POS are usually separate vendor relationships, forcing manual end-of-day reconciliation.
- Small retailers rarely have access to analytics or business intelligence.

Full detail: [docs/01_PROJECT_OVERVIEW.md](../docs/01_PROJECT_OVERVIEW.md).

## Target Users

Small, single-to-few-location retailers (e.g. surf/beach shops, boutique retail, small convenience stores) — an owner-operator or a small owner + staff team, with **no dedicated IT support**, running the business from their own smartphone.

**Market note:** the target market/currency is **Sweden (SEK)**, per [decision D-010](decision.md) — this supersedes the India/INR framing that still appears in some `/docs` examples (currency, GST fields, `Asia/Kolkata` timezone). See [projectStatus.md § Known Issues](projectStatus.md#known-issues) for what still needs updating to reflect this.

## Key Features

1. Merchant self-serve registration & onboarding
2. Authentication (Firebase Auth — owner + staff roles)
3. Dashboard (daily snapshot + AI insights)
4. Inventory management with low-stock alerts
5. Camera-based barcode scanning (no external hardware)
6. AI invoice scanner (OCR + Gemini extraction → inventory update)
7. Billing / cart / checkout
8. Payments via Surfboard Payments
9. Digital, shareable receipts
10. Reports & analytics with AI-generated business insights
11. Settings (tax, receipt template, staff, notifications)

Full detail per feature: [docs/05_FEATURES.md](../docs/05_FEATURES.md).

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), mobile-first |
| Backend | Node.js + Express.js |
| Database | Firebase Realtime Database |
| Authentication | Firebase Authentication |
| Storage | Firebase Storage |
| AI | Gemini API + OCR |
| Payments | Surfboard Payments |

Rationale for every choice above is recorded in [decision.md](decision.md) and [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md).

## Project Structure

```
SurfPOS-AI/
├── .claude/           # This knowledge base — read first, every session
├── docs/              # Full project documentation (18 numbered files)
├── frontend/          # Flutter application (feature-first)
├── backend/           # Node.js + Express API (layered + module-based)
├── firebase/          # Firebase project config (Security Rules, indexes)
├── scripts/           # Setup, deployment, migration, utility scripts
├── api-testing/       # Postman/Bruno API collections
├── design/            # Figma/branding/UI source material
├── .github/           # CI workflows, issue/PR templates
└── .vscode/           # Editor recommendations
```

Full annotated tree: [docs/17_FOLDER_STRUCTURE.md](../docs/17_FOLDER_STRUCTURE.md). **Status: scaffolded, placeholders only — no application code has been written yet.**

## High-Level Architecture

```
Flutter (frontend/) ──Firebase SDKs──> Firebase (Auth · Realtime DB · Storage)
       │
       └──REST (HTTPS)──> Node.js/Express Backend (backend/) ──> Gemini API / OCR
                                                             └──> Surfboard Payments
```

- The Flutter app talks **directly** to Firebase for real-time reads/simple writes, and to the **backend** for anything needing a secret, third-party call, or trusted business logic.
- The backend is the **source of truth for money and stock** — it always re-validates client-submitted data (cart totals, prices) rather than trusting it.
- AI (OCR + Gemini) always **proposes**; a human always **confirms** before anything affecting inventory or money is committed.

Full detail: [docs/02_ARCHITECTURE.md](../docs/02_ARCHITECTURE.md).

## Development Philosophy

- **Documentation and structure before implementation.** The `/docs` knowledge base and the full repository folder scaffold were both created before any application logic, specifically so architecture is decided deliberately rather than discovered ad hoc while coding.
- **Backend as source of truth** for money/stock; client is optimistic UI only.
- **AI proposes, humans confirm** for anything that changes inventory or money.
- **No local server, no local database for the merchant** — the entire product depends on zero-maintenance cloud operation.
- **Mobile-first, one-handed, fast** — every UI decision optimizes for a cashier at a counter (see [docs/06_UI_UX_GUIDE.md § 1](../docs/06_UI_UX_GUIDE.md#1-design-philosophy)).
- **Never duplicate logic** — one service owns each piece of business logic (e.g. inventory mutation, sale-total computation), reused everywhere it's needed.
- **Documentation is maintained, not archived.** This `.claude/` folder and `/docs` are living documents, updated as part of the work itself, not after the fact.

Full coding standards: [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md).

## Current Development Phase

**Phase 0 — Foundations, transitioning into Phase 1 frontend UI** (see [docs/10_TASKS.md](../docs/10_TASKS.md)):
- ✅ Documentation system complete (`/docs`, 18 files)
- ✅ Enterprise repository folder structure scaffolded (`frontend/`, `backend/`, `firebase/`, etc. — placeholders only)
- ✅ `.claude/` Claude knowledge base created (this folder)
- ✅ Frontend design system + reusable widget library complete (`frontend/lib/app/themes/`, `frontend/lib/core/widgets/`) — verified with `flutter analyze`
- 🔄 26-screen premium UI build, one screen at a time — Splash done (1/26), Login next (see [projectStatus.md](projectStatus.md))
- ⬜ Firebase project setup, Surfboard sandbox credentials, Gemini API key provisioning
- ⬜ Resolve pending technical decisions (OCR provider, validation/logging libraries — see [decision.md](decision.md); font is now settled as Inter, see D-012)

Live, authoritative status: [projectStatus.md](projectStatus.md).

## Team Members

| Name | Role | Known identifiers |
|---|---|---|
| Velan | Project owner | Git identity `Velan0404`, email `velan87600@gmail.com` |
| Gopi | Collaborator | GitHub account `Gopi7104` (repository host), git branch `gopi` |

Roles/responsibilities beyond the above are not yet formally documented — update this table as the team's structure becomes clearer.

## Important Links

| Resource | Location |
|---|---|
| GitHub repository | `https://github.com/Gopi7104/SurfPOS-AI` |
| Firebase project | Not yet created — see [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 0 |
| Surfboard Payments sandbox | Not yet provisioned |
| Gemini API key | Not yet provisioned |
| Figma / design source | Not yet added — see [design/](../design/README.md) |

## Documentation Index

| Location | Purpose |
|---|---|
| `.claude/project.md` | This file — project snapshot, read first |
| `.claude/projectStatus.md` | Live progress tracker |
| `.claude/decision.md` | Architectural/technical decision log |
| `.claude/workflow.md` | Development workflow, git strategy, DoD |
| `.claude/commands.md` | Reusable Claude command playbook |
| `.claude/memory.md` | Working memory (temporary, not permanent decisions) |
| `docs/01`–`18` | Full project documentation set — see [docs/12_README.md](../docs/12_README.md) for the index |

---

## Read these files next

Every new Claude Code session in this repository should read, **in this exact order**, before reading or modifying any source code:

1. `.claude/project.md` — this file (you just read it)
2. `.claude/projectStatus.md` — what's actually done, in progress, and blocked right now
3. `.claude/decision.md` — every architectural/technical decision made so far, and why
4. `.claude/memory.md` — current focus, open questions, and temporary notes from the last session
5. [`docs/13_CLAUDE_CONTEXT.md`](../docs/13_CLAUDE_CONTEXT.md) — the detailed project-wide Claude context file
6. [`docs/10_TASKS.md`](../docs/10_TASKS.md) — the full phased roadmap
7. [`docs/07_CODING_RULES.md`](../docs/07_CODING_RULES.md) — the coding standards that apply to any code written afterward

Only after all seven of these should Claude begin reading or modifying source code.
