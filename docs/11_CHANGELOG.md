# 11 — Changelog

> Format follows [Keep a Changelog](https://keepachangelog.com/) conventions and [Semantic Versioning](https://semver.org/). Related: [10_TASKS.md](10_TASKS.md) (what's planned), [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) (why each change was made). **Every merged change must add an entry under `[Unreleased]`**, moved into a version section at release time.

---

## [Unreleased]

### Added
- Complete project documentation system in `/docs` (18 files): project overview, architecture, database design, API reference, feature specs, UI/UX guide, coding rules, architecture decisions, prompt history, task roadmap, README, Claude context file, developer guide, Surfboard integration guide, AI module guide, folder structure, and contributing guide.
- Complete enterprise repository folder structure: `frontend/` (Flutter, feature-first), `backend/` (Node/Express, layered + module-based), `firebase/` (Security Rules config), `scripts/`, `api-testing/`, `design/`, `.github/` (workflows, issue/PR templates), `.vscode/`, plus root `.gitignore`, `LICENSE` (placeholder — unchosen), `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `package.json`. Every folder currently holds only placeholder READMEs/`.gitkeep`/stub entry-point files — no functionality implemented.
- `.claude/` Claude Code knowledge base (`project.md`, `decision.md`, `projectStatus.md`, `workflow.md`, `commands.md`, `memory.md`).
- **First application code in the project:** a complete custom Flutter design system (`frontend/lib/app/themes/` — colors, typography via Inter/`google_fonts`, 8pt spacing, 18-24px radius, motion tokens, soft/glow shadows, full `ThemeData`) and a full reusable widget library (`frontend/lib/core/widgets/` — buttons, cards, text fields, dialogs, bottom sheets, loading/skeletons, empty/error states, app bars, bottom navigation + main scaffold shell, Surfboard brand-mark wrapper), plus the **Splash screen** (screen 1 of 26) wired into `app.dart`/`main.dart`. The official Surfboard Payments logo SVG was downloaded and bundled at `frontend/assets/logos/`. Verified with `flutter analyze` (0 issues across `lib/`) and, on a later verification pass, `flutter test` (3/3 passing). `flutter build web` (release) fails reproducibly on this machine — see `.claude/projectStatus.md § Known Issues #5` (a local Windows Application Control policy blocks Flutter's own shader-compiler binary, unrelated to this code).
- **Mandatory verification workflow** for all future Flutter tasks: `dart format .` → `flutter analyze` (must reach exactly "No issues found!", including INFO-level lints) → `flutter test` → a build check → a fixed-format report. See `.claude/workflow.md § 14` and `.claude/commands.md § Verify & Report`.
- `frontend/android/` platform scaffolded (`flutter create --platforms=android .`) with modern v2 embedding, fixing "Build failed due to use of deleted Android v1 embedding" when running on a connected physical device.
- Screen 2/26 — **Login screen** (`features/authentication/presentation/screens/login_screen.dart`): identifier/password fields with inline validation, forgot-password/create-account/loading/error states, Surfboard logo. Wired Splash → Login (plain `Navigator.pushReplacement`, not `go_router` yet). 6 new widget tests; full suite is 9/9 passing on a real `flutter test` run.

### Changed
- Renamed the planned frontend folder from `mobile/` to `frontend/` across the documentation set to match the actual scaffolded structure (see [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md)).
- `frontend/pubspec.yaml`: added real dependencies (`google_fonts`, `flutter_svg`, `lucide_icons_flutter`) and an `assets:` entry for `assets/logos/`.
- `docs/07_CODING_RULES.md § 1`: Dart/Flutter code-style rule strengthened from "zero warnings" to "exactly `No issues found!`" (zero errors/warnings/infos/lints), cross-referencing the new mandatory verification sequence.
- `frontend/android/README.md`, `frontend/web/README.md`: updated from stale "still a placeholder" notes to reflect their now-scaffolded status.
- `frontend/test/` reorganized to mirror `lib/features/` (Splash tests moved to `test/features/authentication/presentation/screens/`; `test/widget_test.dart` now holds only the app-shell smoke test).
- All widget tests now wrap their subject in `MaterialApp(theme: AppTheme.light, ...)` instead of a bare `MaterialApp`, to test under the app's real theme (see Fixed below).

### Removed
- N/A

### Fixed
- "Build failed due to use of deleted Android v1 embedding" when running on a physical Android device — root cause was `android/` never having been scaffolded; fixed by generating it properly.
- `frontend/lib/core/widgets/loading/skeleton_list.dart`: added `const` in 7 places to resolve `prefer_const_constructors`/`prefer_const_literals_to_create_immutables` analyzer infos (no UI/behavior change).
- Replaced the `lucide_icons` dependency (unmaintained; fails to compile against the current Flutter SDK because `IconData` is now a `final class`) with `lucide_icons_flutter` across all 7 files that used it.
- Three test bugs found while building out Login's test suite: a test tapping a label absent during a loading state, a test's expected string colliding with a field's hint text, and a timer left pending past test end (app.dart's Splash→Login navigation wasn't settled). Plus: tests not using the app's real theme could spuriously trigger the same shader-compiler environment issue via Material 3's default ripple effect — fixed by always testing under `AppTheme.light`.

---

## [0.1.0] — Unreleased (Documentation Baseline)

_This version tag is reserved for "documentation complete, no application code yet." It will be superseded by `0.2.0` at the end of Phase 1 (see [10_TASKS.md](10_TASKS.md))._

### Added
- Initial `/docs` knowledge base (see `[Unreleased]` above for full contents).

---

**Next:** [12_README.md](12_README.md) — the public-facing project README.
