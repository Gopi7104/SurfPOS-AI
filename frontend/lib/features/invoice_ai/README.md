# features/invoice_ai/

AI invoice scanner: photograph a supplier invoice, review OCR + OpenRouter extracted line items, confirm into a purchase order. See docs/05_FEATURES.md § 6 and docs/16_AI_MODULE.md.

Not yet implemented. When implementation begins, this folder follows the standard feature-module shape from [07_CODING_RULES.md § 3](../../../../docs/07_CODING_RULES.md#3-folder-conventions):

```
invoice_ai/
├── data/           # Models (DTOs) + repositories (Firebase SDK / ApiClient calls)
├── domain/         # Entities + use-cases (the actual business rules for this feature)
└── presentation/   # Screens, feature-local widgets, Riverpod providers
```
