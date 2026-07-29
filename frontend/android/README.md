# android/ (Flutter Platform Runner)

**Status: scaffolded** — generated via `flutter create --platforms=android .` (see [docs/09_PROMPT_HISTORY.md](../../docs/09_PROMPT_HISTORY.md) for when), after a physical Android device (`M2101K6I`, Android 13) was connected and `flutter run` failed with "Build failed due to use of deleted Android v1 embedding" against the previous placeholder-only folder.

This is the standard Flutter-generated Android project (Kotlin, Gradle Kotlin DSL, v2 embedding — `flutterEmbedding` meta-data `value="2"` in `app/src/main/AndroidManifest.xml`). Do not hand-edit generated files here beyond what a normal Android/Flutter workflow requires (e.g. `applicationId`, permissions, signing config) — regenerate via `flutter create --platforms=android .` instead of hand-reconstructing if this folder is ever removed.

**Known follow-up:** the package/application ID is still the Flutter default `com.example.surfpos_ai` — change this to a real reverse-domain identifier (e.g. `ai.surfpos.app` or similar, owner's call) before any real device distribution or Play Store submission. Not yet done since it's a business/naming decision, not a technical requirement to run locally.
