# Command Library

> Part of the `.claude/` knowledge base — see [project.md § Read these files next](project.md#read-these-files-next) for the session-start reading order. These are reusable playbooks for common requests in this repository — when a user's request matches one of these shapes, follow the described steps rather than improvising the process from scratch each time.

Every command below assumes the session-start reading order in [project.md](project.md) has already happened. If it hasn't, do that first.

---

### Continue current task

**What Claude should do:**
1. Read [projectStatus.md § In Progress](projectStatus.md#in-progress) and [projectStatus.md § Notes for the Next Claude Session](projectStatus.md#notes-for-the-next-claude-session) to recover exact context.
2. Cross-check against [memory.md § Current Focus](memory.md#current-focus) for anything more granular/temporary than what's in `projectStatus.md`.
3. Verify the assumed state actually holds (`git status`, check the specific files claimed to be in progress) before continuing — do not trust the status file blindly if it looks stale.
4. Resume the work, updating [projectStatus.md](projectStatus.md) and [memory.md](memory.md) as it progresses, not just at the end.

### Create new feature

**What Claude should do:**
1. Confirm the feature is already described in [docs/05_FEATURES.md](../docs/05_FEATURES.md). If not, that's a documentation gap to raise with the user before coding — this project writes docs before/alongside code, not after (see [workflow.md § 2](workflow.md#2-documentation)).
2. Check [decision.md](decision.md) for any open decision the feature depends on (e.g. a library/provider choice) — resolve/confirm first.
3. Scaffold per [docs/17_FOLDER_STRUCTURE.md](../docs/17_FOLDER_STRUCTURE.md): frontend feature gets `data/domain/presentation` under `frontend/lib/features/<name>/`; backend gets routes + controller + service/module + validator.
4. Follow [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md) throughout (size limits, no logic in UI/controllers, validation, error handling).
5. Add/update tests per [docs/18_CONTRIBUTING.md § 5](../docs/18_CONTRIBUTING.md#5-testing-requirements).
6. Update `docs/04_API_DOCUMENTATION.md`/`docs/03_DATABASE_DESIGN.md` if the feature adds endpoints/schema.
7. Update [projectStatus.md](projectStatus.md) and `docs/11_CHANGELOG.md`/`docs/09_PROMPT_HISTORY.md`.

### Fix bug

**What Claude should do:**
1. Reproduce and identify root cause before editing — do not patch a symptom.
2. Check [decision.md](decision.md)/[projectStatus.md § Known Issues](projectStatus.md#known-issues) in case the bug is a known, already-understood gap rather than a novel defect.
3. Fix at the root cause, following existing conventions in the surrounding code (don't refactor unrelated code while fixing a bug — see the project's general "no scope creep" principle).
4. Add a regression test that would have caught the bug.
5. Log the fix in `docs/11_CHANGELOG.md` under `### Fixed`.

### Refactor module

**What Claude should do:**
1. Confirm the refactor doesn't change externally-observable behavior (API shape, schema, UI behavior) — if it does, that's a feature/decision change, not a pure refactor; treat it as such (see "Create new feature" / "Add architectural decision").
2. Check [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md) for the target shape (size limits, layer boundaries, naming) and refactor toward it.
3. Ensure existing tests still pass; add tests first if the module being refactored currently lacks coverage, so the refactor is verifiably behavior-preserving.
4. Update any `/docs` file whose description of the module's internal structure (not just its external contract) is now stale.
5. Log in `docs/11_CHANGELOG.md` under `### Changed`.

### Update documentation

**What Claude should do:**
1. Identify every `/docs` file and `.claude/` file that describes the thing being changed — cross-references in this project are extensive (see [project.md § Documentation Index](project.md#documentation-index)), so a single fact often appears in 2–3 places.
2. Update all of them consistently in the same pass — a partial update (fixing one file but leaving a cross-referenced file stale) is exactly the kind of gap this project has hit before (see [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) and the `mobile/` → `frontend/` cleanup in `docs/09_PROMPT_HISTORY.md`).
3. Add an entry to `docs/09_PROMPT_HISTORY.md` and `docs/11_CHANGELOG.md` describing what was updated and why.
4. Do not silently fix a large cross-cutting documentation inconsistency (like the Sweden/SEK gap) as a side effect of an unrelated request — surface it and confirm scope with the user first if it's large.

### Generate tests

**What Claude should do:**
1. Identify the highest-value untested logic first — per [docs/18_CONTRIBUTING.md § 5](../docs/18_CONTRIBUTING.md#5-testing-requirements), sale-total computation and inventory mutation are the highest bar in this codebase.
2. Write tests that cover both the happy path and at least one failure/validation path.
3. Use the Firebase emulator for anything touching Firebase in an integration test — never production Firebase or a live project.
4. Mirror the source tree structure for the test file location (see [docs/07_CODING_RULES.md § 3](../docs/07_CODING_RULES.md#3-folder-conventions)).

### Review architecture

**What Claude should do:**
1. Read [docs/02_ARCHITECTURE.md](../docs/02_ARCHITECTURE.md) and [decision.md](decision.md) in full first — an architecture review should check consistency with what was already decided, not propose from a blank slate.
2. Check for violations of the core principles: backend as source of truth for money/stock, AI proposes/human confirms, no duplicated business logic, business logic out of UI/controllers (see [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md)).
3. Flag any new cross-cutting concern that should become a new [decision.md](decision.md) entry rather than an undocumented implicit choice.
4. Report findings; do not silently "fix" architecture-level issues without confirming with the user, since these tend to be high-blast-radius changes.

### Review security

**What Claude should do:**
1. Check every backend endpoint against [docs/07_CODING_RULES.md § 11](../docs/07_CODING_RULES.md#11-security): Firebase ID token verified, `merchantId`/`storeId`/`role` ownership re-checked server-side (not just "a valid token exists"), input validated.
2. Check that Firebase Security Rules ([firebase/database.rules.json](../firebase/README.md), `firebase/storage.rules`) independently enforce the same boundaries as the backend (defense in depth — see [docs/02_ARCHITECTURE.md § 11](../docs/02_ARCHITECTURE.md#11-security)).
3. Check webhook handlers (Surfboard) verify signatures and are idempotent (see [docs/15_SURFBOARD_INTEGRATION.md § 5](../docs/15_SURFBOARD_INTEGRATION.md#5-webhooks)).
4. Check no secret ever appears client-side, in logs, or in a committed file (see [docs/07_CODING_RULES.md § 9, § 11](../docs/07_CODING_RULES.md#9-logging)).
5. Report findings; treat any confirmed finding as high-priority regardless of what else is in progress.

### Optimize performance

**What Claude should do:**
1. Check for the specific known performance risks called out in [docs/07_CODING_RULES.md § 12](../docs/07_CODING_RULES.md#12-performance): unbounded/un-indexed RTDB reads, live (non-precomputed) analytics aggregation, synchronous/blocking AI calls, un-`const` Flutter widget subtrees, unpaginated long lists.
2. Measure before and after where practical (don't optimize on intuition alone for anything non-obvious).
3. Never trade away a correctness/security guarantee (e.g. skipping server-side validation) for speed.

### Update project status

**What Claude should do:**
1. Open [projectStatus.md](projectStatus.md) and update: `Completed` (move finished items here), `In Progress`, `Not Started`, `Blockers`, `Known Issues`, `Current Priorities`, `Next Tasks`, `Recently Modified Files`, and `Notes for the Next Claude Session`.
2. Keep entries factual and current — remove/move items rather than letting stale entries accumulate.
3. This should happen as part of finishing any non-trivial unit of work, not as a separately-requested task — but if explicitly asked to "update project status," do a full pass across every section above, not just the one most recently touched.

### Add architectural decision

**What Claude should do:**
1. Confirm a decision has actually been made (by the user, or as an explicit, confirmed recommendation) — this command is for recording decisions, not for making product/architecture calls unilaterally.
2. Append a new entry to [decision.md § Decision Log](decision.md#decision-log) using the [Decision Template](decision.md#decision-template), with the next sequential `D-0XX` number. Never renumber or delete existing entries.
3. If the decision is architecturally significant (technology choice, major pattern), also add a corresponding ADR entry to [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md), cross-referenced from the `decision.md` entry.
4. If the decision reverses an earlier one, mark the earlier entry's Status as `Superseded by D-0YY` rather than editing it away.
