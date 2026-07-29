# 10 — Tasks / Roadmap

> Related: [05_FEATURES.md](05_FEATURES.md) (what each task builds), [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (decisions each task depends on), [11_CHANGELOG.md](11_CHANGELOG.md) (what's actually shipped). Keep this file's **Status** fields current — it is the live source of truth for project progress, unlike the historical [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md).

---

## How to Use This File

Every task has: **Priority** (P0 = blocking/critical, P1 = important, P2 = nice-to-have), **Status** (`Not Started` / `In Progress` / `Blocked` / `Done`), **Dependencies**, **Estimated Time**, **Owner** (`Unassigned` until claimed).

---

## Phase 0 — Foundations (pre-code)

| # | Task | Priority | Status | Dependencies | Est. Time | Owner |
|---|---|---|---|---|---|---|
| 0.1 | Documentation system (this `/docs` set) | P0 | Done | — | 1 day | Claude |
| 0.2 | Resolve pending ADRs (ADR-009 items): OCR provider, validation/logging libs, font | P0 | Not Started | 0.1 | 0.5 day | Unassigned |
| 0.3 | Firebase project setup (Auth, RTDB, Storage) + `database.rules.json` skeleton | P0 | Not Started | 0.2 | 0.5 day | Unassigned |
| 0.4 | Surfboard Payments sandbox/developer account + API credentials | P0 | Not Started | — | Depends on Surfboard onboarding time | Unassigned |
| 0.5 | Gemini API key provisioning | P0 | Not Started | — | 0.25 day | Unassigned |
| 0.6 | Repo scaffolding: `frontend/` (Flutter) + `backend/` (Node/Express) per [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) | P0 | Done | 0.2 | 0.5 day | Claude |

## Phase 1 — MVP (Single Store, Core POS Loop)

| # | Task | Priority | Status | Dependencies | Est. Time | Owner |
|---|---|---|---|---|---|---|
| 1.1 | Firebase Auth integration (sign-up/sign-in, email + phone OTP) | P0 | Not Started | 0.3 | 2 days | Unassigned |
| 1.2 | Merchant Registration flow (`POST /auth/register`, onboarding wizard UI) | P0 | Not Started | 1.1, 0.4 | 3 days | Unassigned |
| 1.3 | Product catalog CRUD (backend + UI) | P0 | Not Started | 0.3 | 3 days | Unassigned |
| 1.4 | Inventory management (view, manual adjust) | P0 | Not Started | 1.3 | 2 days | Unassigned |
| 1.5 | Barcode scanner (camera-based) | P0 | Not Started | 1.3 | 3 days | Unassigned |
| 1.6 | Cart + Billing checkout flow (client-side cart, `POST /sales`) | P0 | Not Started | 1.3, 1.4 | 4 days | Unassigned |
| 1.7 | Surfboard Payments integration (payment intent, device/SDK flow, webhook) | P0 | Not Started | 0.4, 1.6 | 5 days | Unassigned |
| 1.8 | Receipt generation (PDF) + share | P0 | Not Started | 1.7 | 2 days | Unassigned |
| 1.9 | Dashboard (today's snapshot, no AI insights yet) | P1 | Not Started | 1.6 | 2 days | Unassigned |
| 1.10 | Settings (business profile, tax, receipt template) | P1 | Not Started | 1.2 | 2 days | Unassigned |
| 1.11 | Staff accounts + invite flow | P1 | Not Started | 1.1 | 2 days | Unassigned |

## Phase 2 — AI Layer

| # | Task | Priority | Status | Dependencies | Est. Time | Owner |
|---|---|---|---|---|---|---|
| 2.1 | OCR integration (invoice photo → raw text) | P0 | Not Started | 0.2, 1.3 | 3 days | Unassigned |
| 2.2 | Gemini structuring prompt (raw text → line items) | P0 | Not Started | 0.5, 2.1 | 3 days | Unassigned |
| 2.3 | Product matching (fuzzy match + confidence score) | P0 | Not Started | 2.2 | 2 days | Unassigned |
| 2.4 | Invoice scan review UI + confirm/reject flow | P0 | Not Started | 2.3 | 3 days | Unassigned |
| 2.5 | Purchase order creation on confirm (`orders` node, inventory increment) | P0 | Not Started | 2.4 | 2 days | Unassigned |
| 2.6 | Analytics rollup job (daily/monthly precomputation) | P1 | Not Started | 1.6 | 2 days | Unassigned |
| 2.7 | AI business insights generation (Gemini over aggregated sales) | P1 | Not Started | 2.6 | 3 days | Unassigned |
| 2.8 | Dashboard insight cards + Reports screens | P1 | Not Started | 2.6, 2.7 | 3 days | Unassigned |

## Phase 3 — Polish & Hardening

| # | Task | Priority | Status | Dependencies | Est. Time | Owner |
|---|---|---|---|---|---|---|
| 3.1 | Full Firebase Security Rules audit (defense-in-depth pass) | P0 | Not Started | Phase 1 | 2 days | Unassigned |
| 3.2 | Rate limiting + abuse protection on all endpoints | P0 | Not Started | Phase 1 | 1 day | Unassigned |
| 3.3 | Error/empty/loading states audit across all screens ([06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md)) | P1 | Not Started | Phase 1 | 2 days | Unassigned |
| 3.4 | Accessibility pass (contrast, text scaling, tap targets) | P1 | Not Started | Phase 1 | 2 days | Unassigned |
| 3.5 | Dark mode QA | P2 | Not Started | Phase 1 | 1 day | Unassigned |
| 3.6 | Performance pass (list virtualization, `const` audit, RTDB read scoping) | P1 | Not Started | Phase 1–2 | 2 days | Unassigned |

## Future Scope (Not Scheduled)

See [01_PROJECT_OVERVIEW.md § Future Scope](01_PROJECT_OVERVIEW.md#6-future-scope) for the full list. Notable items to eventually schedule as their own phase:

- Multi-store UI (schema already supports it — see ADR-008 in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)).
- Offline sale queueing (see [02_ARCHITECTURE.md § 12](02_ARCHITECTURE.md#12-offline-strategy)).
- Customer loyalty/CRM.
- Supplier-facing portal.
- Flutter Web back-office.
- Hardware add-ons (printer, external scanner).

---

**Next:** [11_CHANGELOG.md](11_CHANGELOG.md) — what has actually shipped, version by version.
