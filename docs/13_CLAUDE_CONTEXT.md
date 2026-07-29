# 13 — Claude Context (Read This First)

> **Every Claude Code session working on this repository must read this file before doing anything else.** It is the single entry point into the rest of the documentation. If something here conflicts with another doc file, the more detailed file wins and this file should be updated to match.

---

## 1. Project Summary

**SurfPOS AI** is a mobile-first, AI-powered cloud POS platform for small retailers, integrated with **Surfboard Payments**. Flutter frontend, Node.js/Express backend, Firebase (Auth + Realtime Database + Storage) as the entire data platform, Gemini API + OCR for AI features (invoice scanning, business insights). Full detail: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md).

## 2. Architecture Summary

- Flutter app talks **directly** to Firebase (Auth/RTDB/Storage) for real-time reads and simple writes, and to the **Node/Express backend** for anything requiring a secret, third-party call, or trusted business logic (payments, AI, sale finalization, analytics).
- Firebase Realtime Database is the single source of truth — no separate SQL/NoSQL datastore. Schema is a flattened JSON tree, denormalized for read speed, partitioned by `merchantId`/`storeId`.
- The backend is stateless, layered (`routes → controllers → services`), and never lets the client be the source of truth for money or stock — it always re-validates.
- Full detail: [02_ARCHITECTURE.md](02_ARCHITECTURE.md), schema: [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md), API: [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md).

## 3. Current Status

**As of 2026-07-29: documentation-only phase. No application code exists yet.** The repository currently contains only `/docs`. See [11_CHANGELOG.md](11_CHANGELOG.md) for the authoritative "what's actually built" record — trust that file over assumptions.

## 4. Completed Work

- Full documentation system (18 files in `/docs`), covering product overview, architecture, database design, API spec, feature specs, UI/UX system, coding rules, ADRs, prompt history, roadmap, changelog, README, this context file, developer guide, Surfboard integration guide, AI module guide, folder structure, and contributing guide.

## 5. Pending Work

Everything in [10_TASKS.md](10_TASKS.md), starting with **Phase 0 (Foundations)**:
- Resolve the open ADR items in [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made) (OCR provider, validation/logging libraries, font) **before** writing code that depends on them.
- Scaffold the actual `mobile/` and `backend/` folders per [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md).
- Set up Firebase project, Surfboard sandbox credentials, Gemini API key.
- Then proceed through Phase 1 (MVP core POS loop) → Phase 2 (AI layer) → Phase 3 (polish/hardening).

## 6. Known Issues

None yet — no application code has been written. This section must be kept current as real issues surface during implementation; do not let it go stale.

## 7. Current Priorities

1. Do not start writing application code until the user explicitly asks — this documentation-only constraint was explicit in the founding request (see [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md)).
2. When code work does begin, start with Phase 0 in [10_TASKS.md](10_TASKS.md) — the pending ADRs block several Phase 1 tasks.
3. Keep this file, [10_TASKS.md](10_TASKS.md), [11_CHANGELOG.md](11_CHANGELOG.md), and [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) updated as living documents as work progresses — they are the memory that lets a future session (human or Claude) pick up without re-reading the whole codebase.

## 8. Coding Rules (Summary — full detail in [07_CODING_RULES.md](07_CODING_RULES.md))

- Feature-first Flutter structure, layered Node structure — never mix conventions (§3 of that doc).
- Small functions (≤30 lines), small components (widget `build()` ≤80 lines, screens ≤350 lines), no god-files.
- No comments except non-obvious *why*. No docstring blocks.
- Business logic never lives in a widget or a controller — it lives in domain/service code, testable in isolation.
- Inventory is only ever mutated through `inventory.service.js`; sale totals are only ever computed in `sales.service.js`. Never duplicate this logic elsewhere.
- Every backend endpoint validates input, verifies the Firebase ID token, and re-checks `merchantId`/`storeId`/`role` ownership before acting — a valid token is not sufficient authorization by itself.
- No secrets in the Flutter app or in git — backend environment variables only.

## 9. Development Philosophy

- **AI proposes, humans confirm** for anything that changes money or stock (invoice scan extraction is always reviewable before it becomes an order).
- **Backend is the source of truth for money and stock** — the client can show optimistic UI, but never trust client-submitted totals/prices.
- **Mobile-first, one-handed, fast** — every UI decision in [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md) optimizes for a cashier at a counter, not a desk user.
- **No local server, no local database for the merchant** — the entire value proposition depends on zero-maintenance cloud operation.
- **Documentation is maintained, not archived.** [10_TASKS.md](10_TASKS.md), [11_CHANGELOG.md](11_CHANGELOG.md), [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md), and [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) must be updated as part of any non-trivial change, not after the fact.

## 10. Important Notes

- The user's working directory historically sits inside a much larger personal git repository (the git root observed at project start was the user's home directory, `C:/Users/velan`, tracking many unrelated projects). **Be careful with any git operation from this project folder** — confirm scope before staging/committing, and never run broad commands like `git add -A` here. This is an environment note, not a SurfPOS AI architectural fact — verify current git state before assuming this is still true.
- Surfboard Payments' exact API surface (endpoint names, auth mechanism, webhook payload shape) is **not yet confirmed against official docs** — [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) describes the integration *pattern* the codebase should follow, not verified real endpoints. Confirm against Surfboard's actual developer documentation before implementing, and update that file + log an ADR once confirmed.
- Several tooling choices are intentionally left open (see [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made)) — do not silently pick one while coding without recording the decision.

## 11. How to Continue Development

1. Read this file, then skim [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md) and [02_ARCHITECTURE.md](02_ARCHITECTURE.md) for context.
2. Check [10_TASKS.md](10_TASKS.md) for the next unclaimed task in priority order, and [11_CHANGELOG.md](11_CHANGELOG.md)/`git log` for what's actually already built (docs can drift — code and git history are ground truth once code exists).
3. Before implementing, check whether the task touches an open ADR item (§ ADR-009) — resolve/confirm it first if so.
4. Follow [07_CODING_RULES.md](07_CODING_RULES.md) and [06_UI_UX_GUIDE.md](06_UI_UX_GUIDE.md) exactly; consult [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) and [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md) before adding any new schema field or endpoint (extend the existing shape, don't invent a parallel one).
5. When done: update [10_TASKS.md](10_TASKS.md) status, add an [11_CHANGELOG.md](11_CHANGELOG.md) entry, add a [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) entry, and add/update an ADR in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md) if a non-trivial decision was made.

---

**See also:** [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) for hands-on setup once code work begins.
