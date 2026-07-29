# 18 — Contributing

> **Updated during the Surfboard-alignment documentation pass** — § 3 and § 4 now include a check for accidental Surfboard-data duplication in Firebase (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)). Related: [07_CODING_RULES.md](07_CODING_RULES.md) (what good code looks like), [21_BACKEND_GUIDELINES.md](21_BACKEND_GUIDELINES.md) (backend layering), [14_DEVELOPER_GUIDE.md](14_DEVELOPER_GUIDE.md) (how to run the project). This file defines *process*; those define *code quality*.

---

## 1. Branch Naming

Format: `<type>/<short-description>`, kebab-case, referencing a task ID from [10_TASKS.md](10_TASKS.md) where applicable.

| Type | Use for | Example |
|---|---|---|
| `feature/` | New functionality | `feature/1.5-barcode-scanner` |
| `fix/` | Bug fixes | `fix/inventory-negative-quantity` |
| `chore/` | Tooling, config, deps, non-functional changes | `chore/eslint-setup` |
| `docs/` | Documentation-only changes | `docs/update-surfboard-integration` |
| `refactor/` | Restructuring without behavior change | `refactor/extract-sales-service` |

`main` is always deployable. Never commit directly to `main` — all work happens on a branch and merges via pull request.

## 2. Commit Message Conventions (Conventional Commits)

Format: `<type>(<scope>): <short summary>`

```
feat(billing): validate cart totals against live product prices
fix(inventory): prevent quantity from going below zero on adjustment
docs(api): document invoice-scan confirm endpoint
refactor(sales): extract tax calculation into shared service
chore(deps): bump firebase-admin to latest
test(inventory): add coverage for low-stock filtering
```

- `type` — one of `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `perf`, `style`.
- `scope` — the feature/module touched (matches [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) feature/service names where possible: `billing`, `inventory`, `ai`, `payments`, etc.).
- Summary: imperative mood ("add", not "added"/"adds"), no trailing period, under ~72 characters.
- Body (optional, for non-trivial changes): explain *why*, same principle as code comments in [07_CODING_RULES.md § 6](07_CODING_RULES.md#6-comments) — the diff already shows *what*.
- Breaking changes: `feat(payments)!: change sale schema to support split payments` with a `BREAKING CHANGE:` footer explaining the migration impact.

## 3. Pull Request Checklist

Before opening a PR, confirm:

- [ ] Branch is up to date with `main` (rebased or merged, no unresolved conflicts).
- [ ] `flutter analyze` / `npm run lint` pass with zero errors.
- [ ] Relevant tests pass locally (`flutter test` / `npm test`) and new logic has test coverage (§5).
- [ ] No secrets, `.env` files, or Firebase service-account JSON are included in the diff.
- [ ] No debug `print`/`console.log` left in the code (see [07_CODING_RULES.md § 9](07_CODING_RULES.md#9-logging)).
- [ ] [10_TASKS.md](10_TASKS.md) status updated for the task(s) this PR addresses.
- [ ] [11_CHANGELOG.md](11_CHANGELOG.md) has a new entry under `[Unreleased]`.
- [ ] If a non-trivial architectural decision was made, it's recorded in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).
- [ ] If this PR changes the database schema or an API contract, [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) / [04_API_DOCUMENTATION.md](04_API_DOCUMENTATION.md) are updated in the same PR — docs and code change together, never in a follow-up "I'll document it later" PR.
- [ ] If this PR adds a new Firebase field/node, it does not duplicate a Surfboard-owned entity (Merchant/Store/Device/Payment/Branding/Tips/Payment Methods) — check [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle) first.

PR description should include: what changed, why (link the [10_TASKS.md](10_TASKS.md) task or issue), and how it was tested (manual steps and/or automated coverage).

## 4. Code Review Expectations

- **Every PR requires at least one review before merge** (self-merging is only acceptable for solo-maintainer periods explicitly acknowledged by the project owner).
- Reviewers check against [07_CODING_RULES.md](07_CODING_RULES.md) explicitly — naming, function/file size limits, no duplicated logic, business logic kept out of the UI/controllers, proper validation and error handling.
- Reviewers check that money/stock-affecting changes still treat the **backend as the source of truth** (see [02_ARCHITECTURE.md § 9](02_ARCHITECTURE.md#9-design-principles)) — flag any change that starts trusting a client-submitted value that was previously server-validated.
- Reviewers check that any new Firebase read/write follows the schema in [03_DATABASE_DESIGN.md](03_DATABASE_DESIGN.md) rather than introducing an ad hoc parallel structure, and specifically that it isn't quietly re-introducing a duplicated copy of a Surfboard-owned object (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)) — this is the single most likely regression now that two systems of record exist.
- Reviewers check that a Service never reaches into another module's Repository or Integration Client directly (see [21_BACKEND_GUIDELINES.md § 8](21_BACKEND_GUIDELINES.md#8-cross-module-rule)).
- Favor requesting changes with a concrete suggestion over a vague "this could be better" — reviews should be actionable.
- Author addresses all comments (via a fix or a reasoned reply) before merge; reviewer re-approves after changes.

## 5. Testing Requirements

- **Flutter:** widget tests for non-trivial UI logic (conditional rendering, form validation feedback); unit tests for all `domain`/use-case classes (these should be trivially testable precisely because business logic is kept out of widgets — see [07_CODING_RULES.md § 14](07_CODING_RULES.md#14-keep-business-logic-out-of-the-ui)).
- **Backend:** unit tests for every `services/*.js` file, especially `sales.service.js` (total/tax computation) and `inventory.service.js` (quantity mutation logic) — these are the money/stock source-of-truth functions and must have the highest coverage bar in the codebase. Integration tests for critical endpoint flows (checkout → payment webhook → sale completion) using a Firebase emulator, not production Firebase.
- **No PR merges with failing tests.** A skipped/pending test must have a linked task in [10_TASKS.md](10_TASKS.md) explaining why, not be silently disabled.
- New endpoints require at least one test covering the validation-failure path (§ [07_CODING_RULES.md § 10](07_CODING_RULES.md#10-validation)), not just the happy path.

---

This is the final file in the documentation set. Start at [13_CLAUDE_CONTEXT.md](13_CLAUDE_CONTEXT.md) or [12_README.md](12_README.md) if picking up this project fresh.
