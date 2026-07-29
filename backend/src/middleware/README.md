# middleware/

Cross-cutting Express middleware:

- `auth.middleware.js` — verifies the Firebase ID token on every protected route (see [docs/07_CODING_RULES.md § 11](../../../docs/07_CODING_RULES.md#11-security))
- `validate.middleware.js` — runs a request against a `validations/` schema before it reaches a controller
- `rateLimit.middleware.js` — per-user rate limiting (see [docs/04_API_DOCUMENTATION.md § 12](../../../docs/04_API_DOCUMENTATION.md#12-rate-limiting--abuse-protection))
- `error.middleware.js` — centralized error handler mapping thrown errors to the standard error envelope (see [docs/07_CODING_RULES.md § 7](../../../docs/07_CODING_RULES.md#7-error-handling))
