# tests/

Automated backend tests, mirroring the `src/` structure per [docs/07_CODING_RULES.md § 3](../docs/07_CODING_RULES.md#3-folder-conventions). Highest coverage bar applies to `src/modules/billing/` and `src/modules/inventory/` — the money/stock source-of-truth logic — see [docs/18_CONTRIBUTING.md § 5](../docs/18_CONTRIBUTING.md#5-testing-requirements).

Run with `npm test` (Vitest, one-shot) or `npm run test:watch`. Requests are made against `src/app.js` directly via `supertest` — no port binding, no real Firebase/Surfboard/OpenRouter calls.

Currently covers the foundational scaffolding only: `health.test.js` (`GET /health`), `notFound.test.js` (404 handler), `response.test.js` (`utils/response.js` envelope helpers). No business-domain module exists yet to test.
