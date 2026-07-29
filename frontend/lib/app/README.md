# app/

App-shell layer: everything needed to bootstrap and wire the Flutter application, as distinct from `core/` (reusable infrastructure) and `features/` (business functionality). See [17_FOLDER_STRUCTURE.md](../../../docs/17_FOLDER_STRUCTURE.md) and [02_ARCHITECTURE.md § 2](../../../docs/02_ARCHITECTURE.md#2-frontend-flutter).

| Folder/File | Purpose |
|---|---|
| `routes/` | `go_router` route definitions and navigation guards (see [02_ARCHITECTURE.md § 2](../../../docs/02_ARCHITECTURE.md#2-frontend-flutter)) |
| `themes/` | `AppTheme` — the single place light/dark color, typography, and spacing tokens are defined (see [06_UI_UX_GUIDE.md](../../../docs/06_UI_UX_GUIDE.md)) |
| `constants/` | App-wide constants and enums that mirror backend values (e.g. `SaleStatus`, see [03_DATABASE_DESIGN.md § 6](../../../docs/03_DATABASE_DESIGN.md#6-naming-conventions)) |
| `configs/` | Build-flavor/environment configuration (API base URL, Firebase options wiring — see [14_DEVELOPER_GUIDE.md § 6](../../../docs/14_DEVELOPER_GUIDE.md#6-environment-variables)) |
| `localization/` | `intl`/ARB localization resources |
| `app.dart` | Root widget: `MaterialApp.router` wiring theme + routes together |

No business logic belongs here — only app bootstrap/wiring (see [07_CODING_RULES.md § 14](../../../docs/07_CODING_RULES.md#14-keep-business-logic-out-of-the-ui)).
