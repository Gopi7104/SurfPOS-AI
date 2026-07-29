# backend/ — SurfPOS AI API

Node.js + Express REST API. Stateless, layered (`routes → controllers → services`), orchestrates Firebase Admin SDK, Gemini API, OCR, and Surfboard Payments. See [docs/02_ARCHITECTURE.md § 3](../docs/02_ARCHITECTURE.md#3-backend-nodejs--express) and [docs/04_API_DOCUMENTATION.md](../docs/04_API_DOCUMENTATION.md).

**Status:** documentation-only scaffold — no backend code has been written yet (see [docs/13_CLAUDE_CONTEXT.md](../docs/13_CLAUDE_CONTEXT.md)).

## Structure

| Folder | Purpose |
|---|---|
| `src/config/` | Env loading/validation, third-party client config |
| `src/routes/` | Express route definitions — thin, no logic |
| `src/controllers/` | Request-in/response-out only — see [docs/07_CODING_RULES.md § 4](../docs/07_CODING_RULES.md#4-component-size-limits) |
| `src/middleware/` | Auth verification, validation, rate limiting, centralized error handling |
| `src/services/` | Shared/cross-cutting business logic |
| `src/modules/` | Domain-specific service modules (auth, merchant, inventory, billing, payments, receipts, analytics, ai, surfboard) |
| `src/firebase/` | Firebase Admin SDK initialization and RTDB/Storage helpers |
| `src/utils/`, `src/constants/`, `src/validators/` | Cross-cutting helpers, constants, request-validation schemas |
| `src/logs/` | Local log output (gitignored — see root `.gitignore`) |
| `src/docs/` | Generated/OpenAPI API documentation (distinct from the project knowledge base in top-level `/docs`) |
| `tests/` | Automated tests, mirrors `src/` |

## Setup

See [docs/14_DEVELOPER_GUIDE.md § 4](../docs/14_DEVELOPER_GUIDE.md#4-node-setup).
