# features/receipts/

Digital receipt preview and share (SMS/email/WhatsApp link). See docs/05_FEATURES.md § 10.

Not yet implemented. When implementation begins, this folder follows the standard feature-module shape from [07_CODING_RULES.md § 3](../../../../docs/07_CODING_RULES.md#3-folder-conventions):

```
receipts/
├── data/           # Models (DTOs) + repositories (Firebase SDK / ApiClient calls)
├── domain/         # Entities + use-cases (the actual business rules for this feature)
└── presentation/   # Screens, feature-local widgets, Riverpod providers
```
