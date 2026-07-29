# scripts/

Operational scripts — not application code. Nothing here implements product functionality; these are one-off or scheduled operator tools.

| Folder | Purpose |
|---|---|
| `setup/` | One-time environment/project bootstrap scripts (e.g. Firebase project setup helpers) — see [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 0 |
| `deployment/` | Deploy scripts for backend/Firebase rules — see [docs/14_DEVELOPER_GUIDE.md § 8](../docs/14_DEVELOPER_GUIDE.md#8-deployment) |
| `migration/` | Data migration scripts (schema changes to the Firebase RTDB tree — see [docs/03_DATABASE_DESIGN.md](../docs/03_DATABASE_DESIGN.md)) |
| `utilities/` | Ad hoc operator utilities (e.g. bulk data export, one-off cleanup) |

No scripts have been written yet.
