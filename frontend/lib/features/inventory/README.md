# features/inventory/

Product catalog and per-store stock management, manual adjustments, low-stock filtering. See docs/05_FEATURES.md § 4.

Not yet implemented. When implementation begins, this folder follows the standard feature-module shape from [07_CODING_RULES.md § 3](../../../../docs/07_CODING_RULES.md#3-folder-conventions):

```
inventory/
├── data/           # Models (DTOs) + repositories (Firebase SDK / ApiClient calls)
├── domain/         # Entities + use-cases (the actual business rules for this feature)
└── presentation/   # Screens, feature-local widgets, Riverpod providers
```
