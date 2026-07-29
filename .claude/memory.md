# Working Memory

> Part of the `.claude/` knowledge base — read after [project.md](project.md), [projectStatus.md](projectStatus.md), and [decision.md](decision.md) (see [project.md § Read these files next](project.md#read-these-files-next)). This file is **temporary and disposable** — current focus, assumptions, reminders, and open questions. **Permanent architectural/technical decisions do not belong here — they belong in [decision.md](decision.md).** Prune this file as items resolve; it should stay short and current, not accumulate forever.

---

## Current Focus

- Just finished creating the `.claude/` knowledge base itself (this file included) — no other work is mid-flight.
- Nothing is currently "in progress" beyond what's recorded in [projectStatus.md § In Progress](projectStatus.md#in-progress).

## Current Assumptions

- The project is documentation/structure-only — no Flutter, Node, or Firebase code exists yet. Don't assume any file under `frontend/lib/`, `backend/src/`, etc. beyond the placeholders exists as real code.
- Sweden/SEK is the **current, correct** target market per [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) — but several `/docs` files still contain India/INR examples. Treat those specific examples as stale, not the rest of the surrounding document.
- Riverpod + `go_router` is the **proposed** (not yet formally confirmed) Flutter state-management/navigation choice — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-007`, Status: Proposed. Don't treat it as settled without checking that ADR's current status first.
- The exact Surfboard Payments API surface is unconfirmed against official docs — everything in `docs/15_SURFBOARD_INTEGRATION.md` is a pattern to verify, not a verified fact.

## Important Reminders

- **Never commit or push git changes without being explicitly asked.** This has held throughout the project so far and should keep holding.
- **Do not write application code unless explicitly asked** — documentation-and-structure-first has been the explicit, repeated instruction across every session so far.
- When updating any fact that appears in multiple docs (a real risk in this project — see the `mobile/` → `frontend/` cleanup and the still-pending Sweden/SEK cleanup), search for all occurrences rather than fixing the first one found.
- Always check `git status` and current branch before assuming what's on disk — branches in this repo (`main`, `velan`, `gopi`) have diverged and reconverged outside of a formal PR process at least once already.

## Pending Questions

_(For the user/project owner — surface these rather than guessing when they become relevant.)_

- Which OCR provider: on-device (e.g. ML Kit) or a cloud OCR API? (Blocks Phase 2 AI work — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`.)
- Which backend validation library (`zod` vs. `Joi`) and logging library (`pino` vs. `winston`)? (Blocks any real backend scaffolding.)
- What license will this project use? (`LICENSE` at repo root is currently a placeholder — "to be determined.")
- What's the actual relationship/roles between Velan and Gopi on this project, and what's the intended branch/merge strategy between `main`, `velan`, and `gopi`? (See [workflow.md § Branch Strategy](workflow.md#branch-strategy).)
- Is Riverpod + `go_router` confirmed, or still open for debate? (`docs/08_ARCHITECTURE_DECISIONS.md § ADR-007` is marked Proposed, not Accepted.)
- Are Surfboard sandbox credentials available yet, and is there official Surfboard API documentation to confirm the integration pattern against?

## Temporary Notes

- The git repository for this project is **independent** of the user's home-directory-rooted mega-repo (`C:/Users/velan`) that also tracks an unrelated "FinTwin AI" project with its own remote (`Velan0404/FinTwin-AI`) — this repo (`SurfPOS AI`) has its own `.git`, pushed to `Gopi7104/SurfPOS-AI`. Don't confuse the two if either comes up.
- Observed git history shows someone ran `git pull origin main` and switched between `velan`/`gopi` branches outside of this session between two of my turns — local branch state can change without my involvement; always re-check before assuming.
- `LICENSE`, Firebase project, Surfboard credentials, and Gemini API key are all real placeholders/TBDs right now, not oversights — don't treat their absence as a bug to silently fix.

## Future Ideas

_(Not decided, not scheduled — candidates for later, sourced from `docs/01_PROJECT_OVERVIEW.md § Future Scope` and conversation so far. Promote to [decision.md](decision.md) only once actually decided.)_

- Multi-store UI (schema already supports it — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-008`).
- Offline sale queueing for unreliable-connectivity checkout.
- Customer loyalty/CRM, supplier-facing portal, Flutter Web back-office.
- Predictive restocking / anomaly detection extensions to the AI insights engine.
- Multi-currency support beyond SEK, if the target market ever expands past Sweden.
