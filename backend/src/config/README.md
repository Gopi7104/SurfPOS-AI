# config/

Loads and validates all environment variables once at boot (fail fast if a required var is missing — see [docs/07_CODING_RULES.md § 15](../../../docs/07_CODING_RULES.md#15-nodejs-best-practices)). Also holds initialization config for third-party clients (Firebase Admin, Gemini, Surfboard) referenced from `src/firebase/` and `src/modules/`.

See [docs/14_DEVELOPER_GUIDE.md § 6](../../../docs/14_DEVELOPER_GUIDE.md#6-environment-variables) for the full environment variable list.
