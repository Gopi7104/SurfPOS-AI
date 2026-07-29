# features/

Feature-first modules — one folder per business capability. Each feature is (or will become, at implementation time) internally organized as `data/` (models + repositories), `domain/` (entities + use-cases/business rules), and `presentation/` (screens, widgets, state) per [07_CODING_RULES.md § 3](../../../docs/07_CODING_RULES.md#3-folder-conventions) and [17_FOLDER_STRUCTURE.md](../../../docs/17_FOLDER_STRUCTURE.md). That internal split is not scaffolded yet — it is added feature-by-feature as each is implemented, not speculatively up front.

| Feature | Purpose | Docs |
|---|---|---|
| `authentication/` | Sign-up/sign-in, staff invites, session/role resolution | [05_FEATURES.md § 2](../../../docs/05_FEATURES.md#2-authentication) |
| `merchant/` | Merchant registration/onboarding and business-profile management | [05_FEATURES.md § 1](../../../docs/05_FEATURES.md#1-merchant-registration) |
| `dashboard/` | Daily snapshot: sales, top products, low stock, AI insights | [05_FEATURES.md § 3](../../../docs/05_FEATURES.md#3-dashboard) |
| `inventory/` | Product catalog + per-store stock, manual adjustments | [05_FEATURES.md § 4](../../../docs/05_FEATURES.md#4-inventory-management) |
| `barcode/` | Camera-based barcode scanning for billing & inventory lookup | [05_FEATURES.md § 5](../../../docs/05_FEATURES.md#5-barcode-scanner) |
| `invoice_ai/` | AI (OCR + Gemini) supplier invoice scanning and review | [05_FEATURES.md § 6](../../../docs/05_FEATURES.md#6-ai-invoice-scanner), [16_AI_MODULE.md](../../../docs/16_AI_MODULE.md) |
| `billing/` | Checkout/payment-collection flow | [05_FEATURES.md § 7](../../../docs/05_FEATURES.md#7-billing) |
| `cart/` | In-progress local cart state before checkout | [05_FEATURES.md § 8](../../../docs/05_FEATURES.md#8-cart) |
| `payments/` | Surfboard Payments status/collection UI | [05_FEATURES.md § 9](../../../docs/05_FEATURES.md#9-payments), [15_SURFBOARD_INTEGRATION.md](../../../docs/15_SURFBOARD_INTEGRATION.md) |
| `receipts/` | Digital receipt preview and sharing | [05_FEATURES.md § 10](../../../docs/05_FEATURES.md#10-receipt) |
| `analytics/` | Reports and AI business insights | [05_FEATURES.md §§ 11–12](../../../docs/05_FEATURES.md#11-reports) |
| `settings/` | Tax, receipt template, notifications, staff management | [05_FEATURES.md § 13](../../../docs/05_FEATURES.md#13-settings) |
| `profile/` | The signed-in user's own account profile (owner or staff) | [05_FEATURES.md § 2](../../../docs/05_FEATURES.md#2-authentication) |

See [07_CODING_RULES.md § 14](../../../docs/07_CODING_RULES.md#14-keep-business-logic-out-of-the-ui) — business logic lives in each feature's `domain/` layer once added, never directly in widgets.
