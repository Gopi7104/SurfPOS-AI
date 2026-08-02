# backend/ — SurfPOS AI API

Node.js + Express REST API. Stateless, layered (`routes → controllers → services`), orchestrates Firebase Admin SDK, OpenRouter (SurfAI), OCR, and Surfboard Payments. See [docs/02_ARCHITECTURE.md § 3](../docs/02_ARCHITECTURE.md#3-backend-nodejs--express) and [docs/04_API_DOCUMENTATION.md](../docs/04_API_DOCUMENTATION.md).

**Status:** foundational scaffolding implemented (Express app, config, logging, error handling, validation, Firebase Admin SDK init, `GET /health`) — no business-domain module (auth, merchant, inventory, billing, etc.) yet. See [docs/13_CLAUDE_CONTEXT.md](../docs/13_CLAUDE_CONTEXT.md).

## Structure

| Folder                                            | Purpose                                                                                                              |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `src/config/`                                     | Env loading/validation, third-party client config                                                                    |
| `src/routes/`                                     | Express route definitions — thin, no logic                                                                           |
| `src/controllers/`                                | Request-in/response-out only — see [docs/07_CODING_RULES.md § 4](../docs/07_CODING_RULES.md#4-component-size-limits) |
| `src/middleware/`                                 | Auth verification, validation, rate limiting, centralized error handling                                             |
| `src/services/`                                   | Shared/cross-cutting business logic                                                                                  |
| `src/modules/`                                    | Domain-specific service modules (auth, merchant, inventory, billing, payments, receipts, analytics, ai, surfboard)   |
| `src/firebase/`                                   | Firebase Admin SDK initialization and RTDB/Storage helpers                                                           |
| `src/utils/`, `src/constants/`, `src/validators/` | Cross-cutting helpers, constants, request-validation schemas                                                         |
| `src/logs/`                                       | Local log output (gitignored — see root `.gitignore`)                                                                |
| `src/docs/`                                       | Generated/OpenAPI API documentation (distinct from the project knowledge base in top-level `/docs`)                  |
| `tests/`                                          | Automated tests, mirrors `src/`                                                                                      |

## Setup

See [docs/14_DEVELOPER_GUIDE.md § 4](../docs/14_DEVELOPER_GUIDE.md#4-node-setup).

## Formatting & linting

Commits used to fail on `npm run format:check` because nothing formatted code before Husky checked it — the check only ever reported problems, it never fixed them, and it ran across the whole backend rather than just what you touched. That's fixed now:

- **Editor**: `.vscode/settings.json` (committed, shared by the team) turns on format-on-save and sets Prettier as the default formatter for JS/JSON/Markdown, and ESLint's quick-fixes on save. It points the ESLint VS Code extension at `backend/` (`eslint.workingDirectories`) so it finds `eslint.config.js`. Install the `esbenp.prettier-vscode` and `dbaeumer.vscode-eslint` extensions (recommended in `.vscode/extensions.json`) and files format themselves as you save — no manual `prettier --write` needed.
- **Pre-commit**: `.husky/pre-commit` now runs `lint-staged` first, which runs `eslint --fix` then `prettier --write` on only the files you staged, and re-stages the result. `npm run lint` and `npm test` then run as a final safety net. A commit only fails now if there's a real lint error `--fix` couldn't resolve, or a failing test — not a formatting nit.
- **Config**: `backend/.prettierrc.json` and `backend/eslint.config.js` are unchanged; `eslint-config-prettier` is already applied last in the ESLint config, so ESLint never fights Prettier over style.

If you edit code outside VS Code (or with format-on-save off), you no longer need to remember to run Prettier — the pre-commit hook does it for you. `npm run format` / `npm run format:check` still exist for manually formatting or CI.
