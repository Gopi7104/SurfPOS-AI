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

### 2026-07-29 — Initial project documentation system

- **Prompt Summary:** User requested a complete documentation-only pass before any application code is written: full architecture, database design, API reference, feature specs, UI/UX guide, coding rules, ADRs, and process docs (18 files total) inside `/docs`, so a future developer or Claude session can understand the entire project without reading a codebase (since no codebase exists yet).
- **Files Changed:** Created `docs/01_PROJECT_OVERVIEW.md` through `docs/18_CONTRIBUTING.md` (all 18 documentation files). No application code was created, per explicit instruction.
- **Reason:** Establish a project knowledge base up front, before implementation begins, so architectural decisions (tech stack, data model, API shape, coding rules) are made deliberately once rather than discovered ad hoc during coding.
- **Decision:** Established the founding architecture decisions in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) (ADR-001 through ADR-008): Flutter frontend, Firebase-only data platform, Node/Express backend, AI-assisted invoice scanning with mandatory human review, smartphone-only hardware model, cloud-only (non-offline-first) architecture, Riverpod state management (proposed, pending confirmation), and a multi-tenant-from-day-one schema with multi-store UI deferred. Several decisions were explicitly left open and logged as pending in ADR-009 (OCR provider, validation/logging libraries, exact Surfboard API surface, production font, insights storage location) — these must be resolved and logged as new ADR entries before or during Phase 1 implementation.

---

**Next:** [10_TASKS.md](10_TASKS.md) — the project roadmap this documentation feeds into.
