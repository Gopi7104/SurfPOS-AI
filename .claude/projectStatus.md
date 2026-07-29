# Project Status

> Read after [project.md](project.md), before [decision.md](decision.md) and [memory.md](memory.md). See [project.md § Read these files next](project.md#read-these-files-next) for the full session-start reading order.
>
> **This file must be updated whenever new work is completed** — it is the live, authoritative snapshot of where the project actually is, as opposed to `docs/10_TASKS.md`'s longer-range roadmap.

---

## Current Phase

**Phase 0 — Foundations** (see [docs/10_TASKS.md](../docs/10_TASKS.md)). No application code has been written. Work so far has been exclusively documentation and repository scaffolding.

## Current Sprint

No formal sprint cadence has been established yet. Work to date has proceeded as a sequence of discrete, explicitly-scoped requests (documentation → folder scaffold → this Claude knowledge base) rather than time-boxed sprints. Establishing a sprint cadence (if wanted) is an open item — see [memory.md § Pending Questions](memory.md#pending-questions).

## Progress Summary

The project exists entirely as **documentation and structure** right now: a full 18-file knowledge base in `/docs`, a complete enterprise repository folder scaffold (placeholders only), and — as of this file — a dedicated `.claude/` Claude session knowledge base. No Flutter, Node, or Firebase code has been written; no Firebase project, Surfboard credentials, or Gemini API key have been provisioned yet.

## Completed

- Full documentation system in `/docs` (18 files: overview, architecture, database design, API reference, features, UI/UX guide, coding rules, ADRs, prompt history, tasks, changelog, README, Claude context, developer guide, Surfboard integration, AI module, folder structure, contributing).
- Full enterprise repository folder structure (`frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/`, root config files) — placeholders (`README.md`/`.gitkeep`/stub entry points) only.
- Reconciliation pass fixing stale `mobile/` → `frontend/` references across the doc set after the folder scaffold was created.
- Git repository initialized (independent of the user's home-directory mega-repo — see [memory.md](memory.md) for that history), pushed to `https://github.com/Gopi7104/SurfPOS-AI.git`.
- `.claude/` Claude knowledge base created (this file, `project.md`, `decision.md`, `workflow.md`, `commands.md`, `memory.md`).

## In Progress

- Nothing mid-flight at the moment — the `.claude/` knowledge base creation is the most recent completed unit of work.

## Not Started

- Phase 1 application implementation (see [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 1: auth integration, product catalog, inventory, barcode scanner, cart/billing, Surfboard payment integration, receipts, dashboard, settings, staff accounts).
- Phase 0 remaining foundation tasks: resolving [decision.md § ADR-009-equivalent open items](decision.md), Firebase project creation, Surfboard sandbox credentials, Gemini API key.
- Propagating the Sweden/SEK market decision ([decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr)) into the affected `/docs` files.

## Blockers

- None hard-blocking at the moment. The open items below are **prerequisites for Phase 1 coding to start cleanly**, not blockers on current documentation/structure work.

## Known Issues

1. **Sweden/SEK decision not yet propagated.** [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) records that Sweden (SEK) is now the target market, but `docs/03_DATABASE_DESIGN.md` (currency, `gstNumber`, `Asia/Kolkata` timezone examples) and other docs still reflect the earlier India/INR framing. Anyone reading those files should treat currency/tax/timezone examples there as **stale** until this is fixed.
2. **Several technical decisions remain open** (tracked informally, not yet given `D-0XX` numbers because nothing has been chosen yet): OCR provider (on-device vs. cloud), backend validation library, backend logging library, production font — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009` for the original list.
3. **Surfboard Payments' exact API surface is unconfirmed** against official documentation — `docs/15_SURFBOARD_INTEGRATION.md` describes an integration *pattern*, not verified endpoints.
4. **Branch/commit hygiene:** this repository currently has per-person branches (`main`, `velan`, `gopi`) that have diverged and re-converged at least once already outside of a formal PR process — see [memory.md](memory.md) for the observed history. No branch/merge strategy has been formally agreed — see [workflow.md § Branch Strategy](workflow.md#branch-strategy) for the proposed convention vs. current actual practice.

## Current Priorities

1. Decide and record the still-open Phase 0 technical decisions (OCR provider, validation/logging libraries, font) as new entries in [decision.md](decision.md).
2. Propagate the Sweden/SEK decision into the affected `/docs` files.
3. Agree a branch/merge strategy for `main` / `velan` / `gopi` before Phase 1 implementation work starts across multiple people at once.
4. Provision Firebase project, Surfboard sandbox credentials, and a Gemini API key.

## Next Tasks

Per [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 0, remaining:

- Task 0.2 — Resolve pending decisions (OCR provider, validation/logging libs, font).
- Task 0.3 — Firebase project setup (Auth, RTDB, Storage) + `database.rules.json` skeleton.
- Task 0.4 — Surfboard Payments sandbox/developer account + API credentials.
- Task 0.5 — Gemini API key provisioning.

Plus, not yet in `docs/10_TASKS.md` (add when scheduled):

- Update `docs/03_DATABASE_DESIGN.md`, `docs/01_PROJECT_OVERVIEW.md`, and any other India/INR-specific examples to reflect Sweden/SEK per [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr).

## Upcoming Milestones

- **Phase 1 — MVP (single store, core POS loop):** auth, catalog, inventory, barcode billing, Surfboard checkout, receipts. See [docs/10_TASKS.md](../docs/10_TASKS.md).
- **Phase 2 — AI layer:** OCR + Gemini invoice scanning, analytics rollups, AI business insights.
- **Phase 3 — Polish & hardening:** security rules audit, rate limiting, accessibility, performance passes.

## Recently Modified Files

- `.claude/project.md`, `.claude/decision.md`, `.claude/projectStatus.md`, `.claude/workflow.md`, `.claude/commands.md`, `.claude/memory.md` — created this session.
- `docs/17_FOLDER_STRUCTURE.md` — rewritten to match the actual scaffolded repository tree.
- `docs/06_UI_UX_GUIDE.md`, `docs/07_CODING_RULES.md`, `docs/09_PROMPT_HISTORY.md`, `docs/10_TASKS.md`, `docs/11_CHANGELOG.md`, `docs/12_README.md`, `docs/13_CLAUDE_CONTEXT.md`, `docs/14_DEVELOPER_GUIDE.md`, `docs/15_SURFBOARD_INTEGRATION.md` — updated to fix stale `mobile/` references and record the folder-scaffold work.
- Root `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `LICENSE`, `.gitignore`, `package.json` — created as part of the repository scaffold.
- Full `frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/` trees — created as placeholders.

## Notes for the Next Claude Session

- Read files in the order specified in [project.md § Read these files next](project.md#read-these-files-next) before touching any code.
- **No application code exists yet** — do not assume any Flutter widget, Express route, or Firebase config beyond the placeholders described in `docs/17_FOLDER_STRUCTURE.md` actually exists. Verify before referencing.
- The Sweden/SEK vs. India/INR inconsistency (Known Issue #1) is real and will confuse anyone who reads `docs/03_DATABASE_DESIGN.md` literally — flag it if it becomes relevant to a task, don't silently "fix" it without being asked, since it touches many files.
- Check current git branch and status before assuming which commit's content is on disk — this repository has had branches diverge/reconverge outside of normal PR flow at least once (see [memory.md](memory.md)).
- Only create git commits or push when explicitly asked, per this project's established working style.
