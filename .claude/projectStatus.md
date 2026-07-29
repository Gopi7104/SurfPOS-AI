# Project Status

> Read after [project.md](project.md), before [decision.md](decision.md) and [memory.md](memory.md). See [project.md § Read these files next](project.md#read-these-files-next) for the full session-start reading order.
>
> **This file must be updated whenever new work is completed** — it is the live, authoritative snapshot of where the project actually is, as opposed to `docs/10_TASKS.md`'s longer-range roadmap.

---

## Current Phase

**Phase 0 — Foundations, transitioning into Phase 1 frontend work** (see [docs/10_TASKS.md](../docs/10_TASKS.md)). The frontend design system and the first screen (Splash) now exist as real, analyzed, tested Flutter code — this is the first application code written in the project. Backend/Firebase/Surfboard integration remain entirely undone.

## Current Sprint

No formal sprint cadence has been established yet. Work to date has proceeded as a sequence of discrete, explicitly-scoped requests (documentation → folder scaffold → this Claude knowledge base) rather than time-boxed sprints. Establishing a sprint cadence (if wanted) is an open item — see [memory.md § Pending Questions](memory.md#pending-questions).

## Progress Summary

Documentation and structure are complete (18-file `/docs` knowledge base, full enterprise folder scaffold, `.claude/` knowledge base). **The frontend now has real code**: a complete custom design system (colors, typography, spacing/radius/motion tokens, shadows, `ThemeData`) and a full reusable widget library (buttons, cards, text fields, dialogs, bottom sheets, loading/skeletons, empty/error states, app bars, bottom navigation, the Surfboard brand mark), plus the Splash screen as the first of 26 planned screens (see the premium-UI design brief in `docs/09_PROMPT_HISTORY.md`). No backend, Firebase, or Surfboard code exists yet; no Firebase project, Surfboard credentials, or Gemini API key have been provisioned.

## Completed

- Full documentation system in `/docs` (18 files: overview, architecture, database design, API reference, features, UI/UX guide, coding rules, ADRs, prompt history, tasks, changelog, README, Claude context, developer guide, Surfboard integration, AI module, folder structure, contributing).
- Full enterprise repository folder structure (`frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/`, root config files) — placeholders (`README.md`/`.gitkeep`/stub entry points) only.
- Reconciliation pass fixing stale `mobile/` → `frontend/` references across the doc set after the folder scaffold was created.
- Git repository initialized (independent of the user's home-directory mega-repo — see [memory.md](memory.md) for that history), pushed to `https://github.com/Gopi7104/SurfPOS-AI.git`.
- `.claude/` Claude knowledge base created (this file, `project.md`, `decision.md`, `workflow.md`, `commands.md`, `memory.md`).
- Frontend design system: `app/themes/{app_colors,app_typography,app_spacing,app_shadows,app_theme}.dart` — custom Blueberry/Cream Soda palette, Inter typography (via `google_fonts`), 8pt spacing/18-24px radius/motion tokens, soft + primary-glow shadow presets, full `ThemeData` assembly. Verified with a clean `flutter analyze`.
- Full reusable widget library under `core/widgets/`: `buttons/` (primary/secondary/icon/FAB), `cards/` (base/stat/insight), `text_fields/` (standard + large search), `dialogs/` (base + confirmation), `bottom_sheets/`, `loading/` (spinner + hand-rolled shimmer skeletons, no external shimmer dependency), `empty_states/` (empty + error), `app_bars/` (standard + gradient hero header), `navigation/` (bottom nav + main scaffold shell with floating "Start New Sale" FAB), `branding/` (Surfboard logo wrapper).
- Official Surfboard Payments logo SVG downloaded and bundled at `frontend/assets/logos/surfboard-payments-white-icon.svg` (it's a **white-only** icon — only legible on a dark/colored background; `SurfboardLogo.badge` wraps it in a Blueberry container for light surfaces, `SurfboardLogo.bare` is for already-dark backgrounds like Splash).
- Screen 1/26 — **Splash screen** implemented (`features/authentication/presentation/screens/splash_screen.dart`): gradient background, animated logo/title entrance, wired into `app/app.dart` + `main.dart`. Verified via `flutter analyze` (0 issues, whole project — errors/warnings/infos/lints all zero) and `flutter test` (**3/3 passing**, confirmed by an actual run). `flutter build web` (release) fails consistently — see Known Issues #5 — this is a machine-local environment restriction, not a code defect.
- Real dependencies added to `frontend/pubspec.yaml`: `google_fonts`, `flutter_svg`, `lucide_icons_flutter` (versions resolved live via `flutter pub add`, not guessed; `lucide_icons` was tried first and replaced — see Known Issues below).
- **`android/` platform scaffolded** (`flutter create --platforms=android .`) after the user connected a physical Android device (`M2101K6I`, Android 13) and hit "Build failed due to use of deleted Android v1 embedding" against the previous placeholder-only folder — root cause was simply that `android/` had never been generated. Confirmed proper v2 embedding (`flutterEmbedding` meta-data `value="2"`). `frontend/android/README.md` and `frontend/web/README.md` updated to reflect scaffolded status (both were stale "still a placeholder" notes). `frontend/.gitignore` comment corrected accordingly.
- Screen 2/26 — **Login screen** implemented (`features/authentication/presentation/screens/login_screen.dart`): identifier/password fields, inline required-field validation (feedback-only), forgot-password/create-account callbacks, loading + error-banner states, Surfboard logo badge. Wired Splash → Login via plain `Navigator.pushReplacement` (not `go_router` — still deferred, see ADR-007). **All 9 widget tests passing** (`flutter test`, actual run, 0 failures) after fixing: (1) the `lucide_icons` package swap below, (2) two genuine test bugs (a tap-target that didn't exist during a loading state; a hint/error-text string collision), (3) a real timer leak (app.dart's now-non-null `SplashScreen.onReady` needed the app-shell test to settle past the 2.2s delayed navigation), and (4) tests not using `AppTheme.light` (see Known Issues below — this made ripple-effect rendering hit the same shader issue as #5, for an avoidable reason).

## In Progress

- Building the remaining 24 screens from the premium-UI design brief, one at a time, per the user's explicit process ("Build one screen at a time"). Next up: **Register**.

## Not Started

- Screens 2–26 (Login, Register, Merchant Onboarding, Dashboard, Inventory, Add Product, Product Details, AI Invoice Scanner, Barcode Scanner, Billing POS, Cart, Payment, Payment Success, Receipt, Sales History, Analytics, AI Assistant, Notifications, Settings, Profile, About, Help & Support — Empty/Error/Loading states are already covered as reusable components, not standalone screens, see Notes below).
- `go_router` navigation wiring — deferred until there's more than one screen to route between (see `.claude/decision.md` ADR-007, still Proposed).
- State management (Riverpod) — not yet introduced; Splash has no state to manage yet.
- Phase 1 data/backend work (auth integration, product catalog, inventory, barcode scanner, cart/billing, Surfboard payment integration, receipts, dashboard, settings, staff accounts) — see [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 1.
- Phase 0 remaining foundation tasks: resolving [decision.md § ADR-009-equivalent open items](decision.md), Firebase project creation, Surfboard sandbox credentials, Gemini API key.
- Propagating the Sweden/SEK market decision ([decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr)) into the affected `/docs` files.

## Blockers

- **`flutter test` / `flutter build` (any release-mode or test target) cannot run on this development machine** — see Known Issues #5. `flutter analyze` still works fine (pure static analysis, no build step), so code-quality verification isn't blocked, but actual runtime/test verification is, until resolved.
- Otherwise none hard-blocking. The open items below are **prerequisites for Phase 1 coding to start cleanly**, not blockers on current documentation/structure work.

## Known Issues

1. **Sweden/SEK decision not yet propagated.** [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) records that Sweden (SEK) is now the target market, but `docs/03_DATABASE_DESIGN.md` (currency, `gstNumber`, `Asia/Kolkata` timezone examples) and other docs still reflect the earlier India/INR framing. Anyone reading those files should treat currency/tax/timezone examples there as **stale** until this is fixed.
2. **Several technical decisions remain open** (tracked informally, not yet given `D-0XX` numbers because nothing has been chosen yet): OCR provider (on-device vs. cloud), backend validation library, backend logging library, production font — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009` for the original list.
3. **Surfboard Payments' exact API surface is unconfirmed** against official documentation — `docs/15_SURFBOARD_INTEGRATION.md` describes an integration *pattern*, not verified endpoints.
4. **Branch/commit hygiene:** this repository currently has per-person branches (`main`, `velan`, `gopi`) that have diverged and re-converged at least once already outside of a formal PR process — see [memory.md](memory.md) for the observed history. No branch/merge strategy has been formally agreed — see [workflow.md § Branch Strategy](workflow.md#branch-strategy) for the proposed convention vs. current actual practice.
5. **`flutter build` is broken on this development machine for every platform tried so far (web release, web debug, Android debug APK); `flutter test` is inconsistent.** **Root cause fully diagnosed:** Windows 11 **Smart App Control** is ON/enforced (registry `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` → `VerifiedAndReputablePolicyState = 1`), and it blocks `impellerc.exe` (Flutter's shader compiler, invoked to precompile Material's `ink_sparkle.frag` ripple shader into every platform's asset bundle) because that binary isn't cloud-reputation-recognized. Confirmed via Flutter's own source (`shader_compiler.dart`) that this step is unconditional for every target platform — no CLI flag skips it. Smart App Control has **no per-app allow-list** (unlike Defender AV exclusions) and is **irreversible without a clean Windows reinstall** once disabled, so it was not disabled unilaterally. **Failed identically 7/7 times** across `flutter build web --release` (2×), `flutter build web --debug` (1×), `flutter build apk --debug` (2×), `flutter run -d <device>` (2×, including one after a full `flutter clean` + `flutter pub get`). `flutter test` is genuinely inconsistent — has both failed (same block) and passed (9/9, 3/3) with no code changes in between. **Confirmed `--no-enable-impeller` does NOT help:** tested empirically (`flutter run --no-enable-impeller`) — identical failure, same `impellerc.exe` invocation with the same Impeller runtime-stage flags. This is expected: the shader precompilation is a build-time asset-bundling step (per Flutter SDK source, unconditional per target platform) that runs *before* the runtime rendering-backend choice is ever consulted; an `AndroidManifest.xml` `EnableImpeller=false` meta-data change couldn't help for the same reason (read even later, at app runtime). No project configuration (`pubspec.yaml`, Gradle files, manifest) forces or customizes shader/Impeller behavior — confirmed by direct inspection, all Gradle/manifest files are stock Flutter-template output. **Agreed path forward (not yet started):** set up Flutter inside WSL2, since Smart App Control doesn't apply to Linux binaries running there — see Known Issues #7 for current status. `flutter analyze` has been fully reliable across every run regardless of this issue.
8. **Separate, unrelated finding:** after a `flutter clean`, `flutter pub get` now warns "Building with plugins requires symlink support. Please enable Developer Mode" — Windows Developer Mode is not enabled on this machine. Did not block `flutter analyze` (still clean) because no current dependency has native platform code requiring symlinks yet, but will likely need addressing once a plugin with native code is added (e.g. camera/barcode packages planned for Phase 1). Not fixed — enabling Developer Mode is a Windows settings change outside the scope of what was authorized when this was found; flag it before it becomes a real blocker.
6. **A `flutter test` run that exercises Material's ripple/ink-splash effect will hit issue #5's shader dependency *even when the underlying build environment is otherwise fine* if the test doesn't use the app's real theme.** Root cause found while building the Login screen: test files that wrap a screen in a bare `MaterialApp` (no `theme:`) get Flutter's Material 3 **default** splash (`InkSparkle`), which needs the `ink_sparkle` shader — whereas the app's actual `AppTheme.light` sets `splashFactory: InkRipple.splashFactory` (the classic ripple, which needs no shader at all) specifically to avoid the Material 3 default look. **Fix applied:** every widget test now wraps its subject in `MaterialApp(theme: AppTheme.light, home: ...)`, not a bare `MaterialApp`. This is a permanent testing convention going forward, not a one-off patch — see `.claude/decision.md` (search "AppTheme.light" in test files before adding a new screen test) and always use it for any test that taps an `InkWell`-based widget (buttons, list tiles, etc.).
7. **WSL2 setup is agreed but not started.** User chose the WSL2 path for issue #5 (see [memory.md](memory.md)); as of the last check, `wsl --status` still reports "not installed." Requires the user to run `wsl --install` as Administrator + restart (I cannot do this myself — no elevation, no ability to trigger/wait through a reboot). Do not assume this is done; re-check `wsl --status` fresh each time it's relevant.

## Current Priorities

1. Decide and record the still-open Phase 0 technical decisions (OCR provider, validation/logging libraries, font) as new entries in [decision.md](decision.md).
2. Propagate the Sweden/SEK decision into the affected `/docs` files.
3. Agree a branch/merge strategy for `main` / `velan` / `gopi` before Phase 1 implementation work starts across multiple people at once.
4. Provision Firebase project, Surfboard sandbox credentials, and a Gemini API key.

## Next Tasks

Per [docs/10_TASKS.md](../docs/10_TASKS.md) Phase 0, remaining:

- Task 0.2 — Resolve pending decisions (OCR provider, validation/logging libs, font).
- Task 0.3 — Firebase project setup (Auth, RTDB, Storage) + `database.rules.json` skeleton.
- Task 0.4 — Surfboard Payments sandbox/developer account + API credentials.
- Task 0.5 — Gemini API key provisioning.

Plus, not yet in `docs/10_TASKS.md` (add when scheduled):

- Update `docs/03_DATABASE_DESIGN.md`, `docs/01_PROJECT_OVERVIEW.md`, and any other India/INR-specific examples to reflect Sweden/SEK per [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr).

## Upcoming Milestones

- **Phase 1 — MVP (single store, core POS loop):** auth, catalog, inventory, barcode billing, Surfboard checkout, receipts. See [docs/10_TASKS.md](../docs/10_TASKS.md).
- **Phase 2 — AI layer:** OCR + Gemini invoice scanning, analytics rollups, AI business insights.
- **Phase 3 — Polish & hardening:** security rules audit, rate limiting, accessibility, performance passes.

## Recently Modified Files

- `.claude/project.md`, `.claude/decision.md`, `.claude/projectStatus.md`, `.claude/workflow.md`, `.claude/commands.md`, `.claude/memory.md` — created this session.
- `docs/17_FOLDER_STRUCTURE.md` — rewritten to match the actual scaffolded repository tree.
- `docs/06_UI_UX_GUIDE.md`, `docs/07_CODING_RULES.md`, `docs/09_PROMPT_HISTORY.md`, `docs/10_TASKS.md`, `docs/11_CHANGELOG.md`, `docs/12_README.md`, `docs/13_CLAUDE_CONTEXT.md`, `docs/14_DEVELOPER_GUIDE.md`, `docs/15_SURFBOARD_INTEGRATION.md` — updated to fix stale `mobile/` references and record the folder-scaffold work.
- Root `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `LICENSE`, `.gitignore`, `package.json` — created as part of the repository scaffold.
- Full `frontend/`, `backend/`, `firebase/`, `scripts/`, `api-testing/`, `design/`, `.github/`, `.vscode/` trees — created as placeholders.

## Notes for the Next Claude Session

- Read files in the order specified in [project.md § Read these files next](project.md#read-these-files-next) before touching any code.
- **No application code exists yet** — do not assume any Flutter widget, Express route, or Firebase config beyond the placeholders described in `docs/17_FOLDER_STRUCTURE.md` actually exists. Verify before referencing.
- The Sweden/SEK vs. India/INR inconsistency (Known Issue #1) is real and will confuse anyone who reads `docs/03_DATABASE_DESIGN.md` literally — flag it if it becomes relevant to a task, don't silently "fix" it without being asked, since it touches many files.
- Check current git branch and status before assuming which commit's content is on disk — this repository has had branches diverge/reconverge outside of normal PR flow at least once (see [memory.md](memory.md)).
- Only create git commits or push when explicitly asked, per this project's established working style.
- **Do not run `flutter test` or `flutter build` and assume/report success without reading the actual output.** On this machine both currently fail on a blocked `impellerc.exe` (see Known Issues #5) — `flutter analyze` is the only verification tool confirmed to work here. If this is fixed later (or you're on a different machine), re-verify and update this note.
