# Development Workflow

> Part of the `.claude/` knowledge base — see [project.md § Read these files next](project.md#read-these-files-next) for the session-start reading order. This file describes the **end-to-end process** work should follow; the human-facing Git/PR mechanics live in [docs/18_CONTRIBUTING.md](../docs/18_CONTRIBUTING.md) and are cross-referenced rather than duplicated below.

---

## 1. Planning

- New work starts from [docs/10_TASKS.md](../docs/10_TASKS.md) (the phased roadmap) or a specific user request.
- Before implementing anything non-trivial, confirm: does this touch an open item in [decision.md](decision.md) (an unresolved technical choice)? If so, resolve/confirm the decision **first** and record it, rather than silently picking an approach mid-implementation.
- For ambiguous or multi-approach work, use a plan-first pass (the Plan agent / plan mode) before writing code — see [commands.md](commands.md) for the relevant command shape.

## 2. Documentation

- Documentation is written **before or alongside** the code it describes, not after. This project's own history (docs → folder scaffold → `.claude/` knowledge base, all before any application code) is the model to follow.
- Any new schema field, endpoint, or feature behavior is documented in the relevant `/docs` file ([03_DATABASE_DESIGN.md](../docs/03_DATABASE_DESIGN.md), [04_API_DOCUMENTATION.md](../docs/04_API_DOCUMENTATION.md), [05_FEATURES.md](../docs/05_FEATURES.md)) in the same change as the code, not a follow-up.
- Non-trivial decisions made along the way are recorded in [decision.md](decision.md) (and cross-referenced into [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md)) as they're made, not reconstructed from memory later.

## 3. Design

- UI work follows [docs/06_UI_UX_GUIDE.md](../docs/06_UI_UX_GUIDE.md) (color, type, spacing, component inventory) — new screens should be buildable almost entirely from the existing shared widget inventory in `frontend/lib/core/widgets/`.
- Design-source material (Figma exports, branding, mockups) lives in [design/](../design/README.md), separate from production-ready bundled assets in `frontend/assets/`.
- A new custom widget that isn't a one-off is a signal to add it to the shared component inventory rather than re-creating it per screen.

## 4. Backend Development

- Follow the layered shape strictly: `routes/ → controllers/ → services/` (or the relevant `modules/<name>/`) `→ Firebase Admin SDK / external API`. A controller never talks to Firebase directly (see [docs/07_CODING_RULES.md § 3](../docs/07_CODING_RULES.md#3-folder-conventions)).
- Money/stock-affecting logic (`inventory.service.js`-equivalent, `sales`/`billing` totals) is the single most safety-critical code in the system — see [docs/07_CODING_RULES.md § 8](../docs/07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services). It must never be duplicated, and the client's submitted values are never trusted as the source of truth.
- Every endpoint: validate input → verify Firebase ID token → re-check `merchantId`/`storeId`/`role` ownership → act (see [docs/07_CODING_RULES.md § 11](../docs/07_CODING_RULES.md#11-security)).

## 5. Frontend Development

- Follow the feature-first shape: `frontend/lib/features/<name>/{data,domain,presentation}` (added per-feature as each is implemented, not scaffolded speculatively — see [docs/17_FOLDER_STRUCTURE.md § Feature-folder rationale](../docs/17_FOLDER_STRUCTURE.md#feature-folder-rationale)).
- Business logic (validation beyond simple UX feedback, price/total calculation, matching/confidence logic) lives in `domain/`, never inside a widget's `build()` or an `onPressed` closure (see [docs/07_CODING_RULES.md § 14](../docs/07_CODING_RULES.md#14-keep-business-logic-out-of-the-ui)).
- State management is Riverpod, navigation is `go_router` — no mixing in a second approach for convenience (see [decision.md](decision.md) and `docs/08_ARCHITECTURE_DECISIONS.md § ADR-007`, currently **Proposed**, not yet formally confirmed — check its status before assuming it's final).

## 6. Testing

- Backend: unit tests per service, especially anything computing sale totals or mutating inventory — highest coverage bar in the codebase (see [docs/18_CONTRIBUTING.md § 5](../docs/18_CONTRIBUTING.md#5-testing-requirements)). Integration tests for checkout → payment webhook → sale completion, against a Firebase emulator, never production Firebase.
- Frontend: widget tests for non-trivial UI logic; unit tests for all `domain`/use-case classes.
- No PR merges with failing tests, and no new endpoint merges without a validation-failure-path test, not just the happy path.

## 7. Integration

- Third-party integrations (Surfboard Payments, Gemini, OCR) are each isolated behind their own backend module/service (`backend/src/modules/surfboard/`, `backend/src/modules/ai/`) — never called directly from a controller (see [docs/07_CODING_RULES.md § 8](../docs/07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services)).
- Webhooks (Surfboard payment status) must verify signatures and be idempotent — see [docs/15_SURFBOARD_INTEGRATION.md § 5](../docs/15_SURFBOARD_INTEGRATION.md#5-webhooks).
- AI outputs (Gemini structuring, OCR text) are always validated before being trusted/stored, and anything affecting inventory/money always requires human confirmation (see [decision.md § D-007](decision.md#d-007--ai-invoice-ocr-approach)).

## 8. Deployment

- Environment separation is strict: separate Firebase projects and Surfboard credential sets for `dev`/`staging`/`production` — never point a release build at sandbox credentials or vice versa (see [docs/14_DEVELOPER_GUIDE.md § 8](../docs/14_DEVELOPER_GUIDE.md#8-deployment)).
- Firebase Security Rules and indexes are deployed from version-controlled files in [firebase/](../firebase/README.md) — never edited ad hoc only in the Firebase console (see [docs/07_CODING_RULES.md § 16](../docs/07_CODING_RULES.md#16-firebase-best-practices)).
- Exact deployment target (Cloud Run vs. another host) is still an open decision — see [docs/14_DEVELOPER_GUIDE.md § 8](../docs/14_DEVELOPER_GUIDE.md#8-deployment) and record the final choice in [decision.md](decision.md) once made.

## 9. Maintenance

- Every non-trivial change updates, in the same unit of work: [projectStatus.md](projectStatus.md) (status), [docs/11_CHANGELOG.md](../docs/11_CHANGELOG.md) (changelog entry), [docs/09_PROMPT_HISTORY.md](../docs/09_PROMPT_HISTORY.md) (session log), and [decision.md](decision.md)/[docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md) (if a decision was made).
- Known issues and stale documentation (e.g. the current Sweden/SEK propagation gap — see [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr)) are tracked in [projectStatus.md § Known Issues](projectStatus.md#known-issues) until resolved, not left implicit.

## 10. Git Workflow

- Full commit-message conventions (Conventional Commits) and PR checklist are defined in [docs/18_CONTRIBUTING.md §§ 2–3](../docs/18_CONTRIBUTING.md#2-commit-message-conventions-conventional-commits) — follow them as written.
- **Never commit or push without being explicitly asked.** This has been the established working pattern in this project so far — git state changes (commits, pushes, branch switches) are confirmed with the user first, or done only when the user's instruction directly implies it (e.g. "git push" after a reviewed set of changes).
- Before any operation that could discard uncommitted work (`checkout`, `reset`, `clean`), check `git status` first.

## 11. Branch Strategy

- **Current actual practice, as observed:** branches named after individual contributors exist — `main`, `velan`, `gopi` — alongside `main` as the presumed integration branch. These have already diverged and been fast-forwarded back in sync at least once outside of a formal PR (see [memory.md](memory.md)).
- **Documented target convention** (per [docs/18_CONTRIBUTING.md § 1](../docs/18_CONTRIBUTING.md#1-branch-naming)): type-prefixed branches (`feature/…`, `fix/…`, `chore/…`, `docs/…`, `refactor/…`), merged into `main` via PR, with `main` always deployable.
- **These two are not yet reconciled.** Until the project owner decides otherwise, treat per-person branches (`velan`, `gopi`) as existing personal working branches, and prefer merging/rebasing them against `main` via PR before layering type-prefixed feature branches on top — but do not unilaterally restructure existing branches without asking. Record the final agreed convention as a new entry in [decision.md](decision.md) once settled.

## 12. Code Review

- Every PR requires at least one review before merge (self-merge only during explicitly-acknowledged solo-maintainer periods) — see [docs/18_CONTRIBUTING.md § 4](../docs/18_CONTRIBUTING.md#4-code-review-expectations).
- Reviewers check against [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md) explicitly, and specifically whether a change starts trusting a client-submitted value that was previously server-validated (a regression in the "backend is source of truth" principle is the single most important thing to catch).

## 13. Definition of Done

A change is **done** only when all of the following are true:

- [ ] Code follows [docs/07_CODING_RULES.md](../docs/07_CODING_RULES.md) (naming, size limits, no duplicated logic, business logic out of UI/controllers).
- [ ] Relevant `/docs` files are updated in the same change (schema, API, feature spec — whatever the change touches).
- [ ] Tests pass and cover the new logic, including the validation-failure path for new endpoints.
- [ ] No secrets, `.env` files, or service-account credentials are in the diff.
- [ ] [projectStatus.md](projectStatus.md), [docs/11_CHANGELOG.md](../docs/11_CHANGELOG.md), and [docs/09_PROMPT_HISTORY.md](../docs/09_PROMPT_HISTORY.md) are updated.
- [ ] Any non-trivial decision made along the way is recorded in [decision.md](decision.md) (and, if architectural, in [docs/08_ARCHITECTURE_DECISIONS.md](../docs/08_ARCHITECTURE_DECISIONS.md)).
- [ ] Nothing was committed or pushed without being asked.
