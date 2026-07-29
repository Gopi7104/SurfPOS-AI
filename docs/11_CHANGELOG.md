# 11 — Changelog

> Format follows [Keep a Changelog](https://keepachangelog.com/) conventions and [Semantic Versioning](https://semver.org/). Related: [10_TASKS.md](10_TASKS.md) (what's planned), [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) (why each change was made). **Every merged change must add an entry under `[Unreleased]`**, moved into a version section at release time.

---

## [Unreleased]

### Added
- Complete project documentation system in `/docs` (18 files): project overview, architecture, database design, API reference, feature specs, UI/UX guide, coding rules, architecture decisions, prompt history, task roadmap, README, Claude context file, developer guide, Surfboard integration guide, AI module guide, folder structure, and contributing guide.
- Complete enterprise repository folder structure: `frontend/` (Flutter, feature-first), `backend/` (Node/Express, layered + module-based), `firebase/` (Security Rules config), `scripts/`, `api-testing/`, `design/`, `.github/` (workflows, issue/PR templates), `.vscode/`, plus root `.gitignore`, `LICENSE` (placeholder — unchosen), `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `package.json`. Every folder currently holds only placeholder READMEs/`.gitkeep`/stub entry-point files — no functionality implemented.

### Changed
- Renamed the planned frontend folder from `mobile/` to `frontend/` across the documentation set to match the actual scaffolded structure (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).

### Removed
- N/A

### Fixed
- N/A

---

## [0.1.0] — Unreleased (Documentation Baseline)

_This version tag is reserved for "documentation complete, no application code yet." It will be superseded by `0.2.0` at the end of Phase 1 (see [10_TASKS.md](10_TASKS.md))._

### Added
- Initial `/docs` knowledge base (see `[Unreleased]` above for full contents).

---

**Next:** [12_README.md](12_README.md) — the public-facing project README.
