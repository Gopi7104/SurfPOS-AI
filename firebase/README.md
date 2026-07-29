# firebase/

Firebase project configuration, version-controlled per [docs/07_CODING_RULES.md § 16](../docs/07_CODING_RULES.md#16-firebase-best-practices) ("Security Rules are version-controlled... never edited ad hoc only in the Firebase console").

| File | Purpose |
|---|---|
| `firebase.json` | Firebase CLI project config (which rules/hosting/functions targets deploy where) |
| `database.rules.json` | Realtime Database Security Rules — see [docs/03_DATABASE_DESIGN.md § 8](../docs/03_DATABASE_DESIGN.md#8-security-rules-summary) |
| `indexes.json` | Reference documentation of the `.indexOn` declarations expected inside `database.rules.json` — see [docs/03_DATABASE_DESIGN.md § 7](../docs/03_DATABASE_DESIGN.md#7-indexes) for the authoritative list; kept here as a flat, reviewable index changelog |
| `storage.rules` | Firebase Storage Security Rules (invoice scans, receipts, product images) |

All files here are placeholders — no rules have been authored yet. See [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 0, task 0.3.
