# assets/

Static binary assets bundled into the Flutter app, referenced from `pubspec.yaml` under the `flutter: assets:` / `flutter: fonts:` sections once populated.

| Folder | Contents |
|---|---|
| `images/` | Raster/vector illustrations, onboarding artwork, empty-state imagery (see [06_UI_UX_GUIDE.md § 9](../../docs/06_UI_UX_GUIDE.md#9-design-system-component-inventory)) |
| `icons/` | Custom icon assets not covered by the Material Symbols set (see [06_UI_UX_GUIDE.md § 5](../../docs/06_UI_UX_GUIDE.md#5-icons)) |
| `animations/` | Lottie/Rive animation files used for purposeful motion (see [06_UI_UX_GUIDE.md § 7](../../docs/06_UI_UX_GUIDE.md#7-animations)) |
| `fonts/` | Bundled font files for the app typeface (see [06_UI_UX_GUIDE.md § 3](../../docs/06_UI_UX_GUIDE.md#3-typography)) |
| `logos/` | SurfPOS AI brand logo variants (light/dark, square/wide) |
| `sounds/` | Feedback sounds (e.g. barcode-scan confirmation — see [05_FEATURES.md § 5](../../docs/05_FEATURES.md#5-barcode-scanner)) |
| `test_fixtures/` | Sample/mock media for manual testing only — **not** bundled via `pubspec.yaml`, never referenced by app code. E.g. a mock product label PNG for exercising Inventory's Product Image picker. |

Each subfolder currently holds only a `.gitkeep` placeholder (except `test_fixtures/`) — no shipped assets have been added yet. Do not commit large/unoptimized binaries; compress images and keep fonts to the weights actually used.
