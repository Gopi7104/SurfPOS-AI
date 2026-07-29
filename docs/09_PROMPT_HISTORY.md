# 09 — Prompt History

> This file is Claude's memory of *why* the codebase looks the way it does, across sessions. **Every future Claude Code session that makes a non-trivial change must append an entry here** before finishing. Read alongside [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md) and [11_CHANGELOG.md](11_CHANGELOG.md) (this file explains the *why*; the changelog records the *what*, user-facing).

---

## How to Add an Entry

Append a new entry at the **top** of the log (§2), directly under this heading, using the template below. Do not edit or delete past entries — this is a historical record.

```markdown
### YYYY-MM-DD — <short title>

- **Prompt Summary:** What the user asked for, in 1–3 sentences.
- **Files Changed:** List of files/folders touched.
- **Reason:** Why this work was requested (business/technical motivation).
- **Decision:** Any decision made while doing the work (link a new/updated ADR in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) if applicable).
```

---

## Log

### 2026-07-29 — Enterprise repository folder structure scaffold

- **Prompt Summary:** User requested the complete project folder structure be created before any application code — folders, placeholder files, and README.md files only, following a professional enterprise architecture, with an explicit tree spanning `frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/`, and root-level config files.
- **Files Changed:** Created the full directory tree (87 folders) with placeholder `README.md`/`.gitkeep` files and stub entry points (`main.dart`, `app.dart`, `app.js`, `server.js` — comments only, no logic); placeholder manifests (`pubspec.yaml`, both `package.json` files, `.env.example`); placeholder Firebase config (`firebase.json`, `database.rules.json`, `storage.rules`, `indexes.json`); root `.gitignore`, `LICENSE` (unchosen, left as a decision for the project owner), `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`. Updated `docs/17_FOLDER_STRUCTURE.md` to match the actual scaffold and fixed stale `mobile/` → `frontend/` references in `docs/10_TASKS.md`, `docs/12_README.md`, `docs/13_CLAUDE_CONTEXT.md`, `docs/14_DEVELOPER_GUIDE.md`, `docs/15_SURFBOARD_INTEGRATION.md`, `docs/06_UI_UX_GUIDE.md`, and `docs/07_CODING_RULES.md`.
- **Reason:** Establish a navigable, professional repository skeleton so implementation work (Phase 1 onward per [10_TASKS.md](10_TASKS.md)) has an agreed folder for every concern before any code is written, consistent with the "documentation and structure before implementation" approach set at project start.
- **Decision:** The user's provided tree used `frontend/` (not the `mobile/` name assumed in the original `08_ARCHITECTURE_DECISIONS.md`/`17_FOLDER_STRUCTURE.md` draft) and introduced two feature folders not previously specified in `05_FEATURES.md` — `merchant/` (business profile, split out from the original combined Merchant Registration + Settings scope) and `profile/` (the signed-in user's own account profile, split out from Authentication). Folder names `barcode_scanner/`/`invoice_scanner/` were renamed to `barcode/`/`invoice_ai/`. No new feature *behavior* was defined — only folder scaffolding and cross-reference updates. The per-feature internal `data/domain/presentation` split documented in `07_CODING_RULES.md` was **not** scaffolded inside each feature folder yet — it is added feature-by-feature as each is actually implemented, to avoid speculative empty structure. The Node backend's Security Rules and Firebase config were placed in a dedicated top-level `firebase/` folder (matching the user's tree) rather than inside `backend/`, which supersedes the original `17_FOLDER_STRUCTURE.md` draft that had `database.rules.json` living under `backend/`.

### 2026-07-29 — Initial project documentation system

- **Prompt Summary:** User requested a complete documentation-only pass before any application code is written: full architecture, database design, API reference, feature specs, UI/UX guide, coding rules, ADRs, and process docs (18 files total) inside `/docs`, so a future developer or Claude session can understand the entire project without reading a codebase (since no codebase exists yet).
- **Files Changed:** Created `docs/01_PROJECT_OVERVIEW.md` through `docs/18_CONTRIBUTING.md` (all 18 documentation files). No application code was created, per explicit instruction.
- **Reason:** Establish a project knowledge base up front, before implementation begins, so architectural decisions (tech stack, data model, API shape, coding rules) are made deliberately once rather than discovered ad hoc during coding.
- **Decision:** Established the founding architecture decisions in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (ADR-001 through ADR-008): Flutter frontend, Firebase-only data platform, Node/Express backend, AI-assisted invoice scanning with mandatory human review, smartphone-only hardware model, cloud-only (non-offline-first) architecture, Riverpod state management (proposed, pending confirmation), and a multi-tenant-from-day-one schema with multi-store UI deferred. Several decisions were explicitly left open and logged as pending in ADR-009 (OCR provider, validation/logging libraries, exact Surfboard API surface, production font, insights storage location) — these must be resolved and logged as new ADR entries before or during Phase 1 implementation.

---

**Next:** [10_TASKS.md](10_TASKS.md) — the project roadmap this documentation feeds into.
