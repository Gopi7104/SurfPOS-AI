# core/

Reusable infrastructure shared across every feature — never feature-specific business logic (that belongs in `features/<name>/`, see [17_FOLDER_STRUCTURE.md](../../../docs/17_FOLDER_STRUCTURE.md)).

| Folder | Purpose |
|---|---|
| `services/` | Cross-feature services (e.g. a shared Firebase Storage upload helper) — see [17_FOLDER_STRUCTURE.md § 2](../../../docs/17_FOLDER_STRUCTURE.md#2-mobile-flutter--full-tree) |
| `network/` | `ApiClient` (dio wrapper) and the auth-token attach interceptor — see [02_ARCHITECTURE.md § 2](../../../docs/02_ARCHITECTURE.md#2-frontend-flutter) |
| `utils/` | Pure helper functions (formatting, string/number utilities) |
| `helpers/` | Small cross-cutting helpers that don't warrant their own service |
| `storage/` | Local device storage wrappers (cached catalog/barcode index — see [02_ARCHITECTURE.md § 12](../../../docs/02_ARCHITECTURE.md#12-offline-strategy)) |
| `exceptions/` | Typed exception classes surfaced from `network`/`services` to feature code |
| `validators/` | Shared client-side input validators (feedback-only — see [07_CODING_RULES.md § 10](../../../docs/07_CODING_RULES.md#10-validation)) |
| `widgets/` | The shared component inventory (`PrimaryButton`, `AppCard`, `StatusBadge`, `EmptyState`, etc. — see [06_UI_UX_GUIDE.md § 9](../../../docs/06_UI_UX_GUIDE.md#9-design-system-component-inventory)) |

Rule of thumb: if two or more features need the same logic, it belongs here, not duplicated in each feature (see [07_CODING_RULES.md § 8](../../../docs/07_CODING_RULES.md#8-never-duplicate-logic--always-reuse-services)).
