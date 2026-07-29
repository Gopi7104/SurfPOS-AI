# Working Memory

> Part of the `.claude/` knowledge base — read after [project.md](project.md), [projectStatus.md](projectStatus.md), and [decision.md](decision.md) (see [project.md § Read these files next](project.md#read-these-files-next)). This file is **temporary and disposable** — current focus, assumptions, reminders, and open questions. **Permanent architectural/technical decisions do not belong here — they belong in [decision.md](decision.md).** Prune this file as items resolve; it should stay short and current, not accumulate forever.

---

## Current Focus

- Building the premium Flutter UI per the "Senior Flutter UI/UX Engineer" design brief: full custom design system (done) + 26 screens, one at a time (Splash done, 25 to go — see [projectStatus.md](projectStatus.md)).
- Next screen up: **Login**.
- The design system + widget library is verified clean (`flutter analyze`: 0 issues — errors, warnings, infos, and lints all zero, confirmed after fixing 7 `prefer_const_constructors`/`prefer_const_literals_to_create_immutables` infos in `skeleton_list.dart`). `flutter test` has passed (3/3) on a confirmed run, but also failed once on the same `impellerc.exe` Application Control block seen with `flutter build web` (release) — which has failed consistently on every attempt (2/2). See `projectStatus.md § Known Issues #5` for the full nuance: don't assume a single passing test run means it's reliable, and don't assume a passing test run implies a release build will also succeed on this machine.
- **A mandatory verification workflow is now in force for every task** (format → analyze-until-clean → test → build, then a fixed-format report) — see `.claude/workflow.md § Definition of Done` and `.claude/commands.md`. Follow it before considering any task complete, starting now.

## Current Assumptions

- Documentation/structure is complete project-wide, but **the frontend now has real code**: full design system + widget library, plus Splash (1/26 screens). Backend/Firebase remain entirely placeholder. Don't assume any file under `backend/src/` etc. is real, but do assume `frontend/lib/app/themes/` and `frontend/lib/core/widgets/` are real and should be reused, not recreated.
- **WSL2 setup is agreed but NOT started.** The user chose "set up Flutter inside WSL2" as the fix for the Windows Smart App Control block (see Temporary Notes below), but as of the last check, `wsl --status` still reports "The Windows Subsystem for Linux is not installed" — the user has not yet run `wsl --install` as Administrator + restarted. Do not assume WSL exists; check `wsl --status` fresh each time this comes up before proceeding with Flutter/Android SDK setup inside it.
- Sweden/SEK is the **current, correct** target market per [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) — but several `/docs` files still contain India/INR examples. Treat those specific examples as stale, not the rest of the surrounding document.
- Riverpod + `go_router` is the **proposed** (not yet formally confirmed) Flutter state-management/navigation choice — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-007`, Status: Proposed. Don't treat it as settled without checking that ADR's current status first.
- The exact Surfboard Payments API surface is unconfirmed against official docs — everything in `docs/15_SURFBOARD_INTEGRATION.md` is a pattern to verify, not a verified fact.

## Important Reminders

- **Never commit or push git changes without being explicitly asked.** This has held throughout the project so far and should keep holding.
- **Do not write application code unless explicitly asked** — documentation-and-structure-first has been the explicit, repeated instruction across every session so far.
- When updating any fact that appears in multiple docs (a real risk in this project — see the `mobile/` → `frontend/` cleanup and the still-pending Sweden/SEK cleanup), search for all occurrences rather than fixing the first one found.
- Always check `git status` and current branch before assuming what's on disk — branches in this repo (`main`, `velan`, `gopi`) have diverged and reconverged outside of a formal PR process at least once already.

## Pending Questions

_(For the user/project owner — surface these rather than guessing when they become relevant.)_

- Which OCR provider: on-device (e.g. ML Kit) or a cloud OCR API? (Blocks Phase 2 AI work — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-009`.)
- Which backend validation library (`zod` vs. `Joi`) and logging library (`pino` vs. `winston`)? (Blocks any real backend scaffolding.)
- What license will this project use? (`LICENSE` at repo root is currently a placeholder — "to be determined.")
- What's the actual relationship/roles between Velan and Gopi on this project, and what's the intended branch/merge strategy between `main`, `velan`, and `gopi`? (See [workflow.md § Branch Strategy](workflow.md#branch-strategy).)
- Is Riverpod + `go_router` confirmed, or still open for debate? (`docs/08_ARCHITECTURE_DECISIONS.md § ADR-007` is marked Proposed, not Accepted.)
- Are Surfboard sandbox credentials available yet, and is there official Surfboard API documentation to confirm the integration pattern against?

## Temporary Notes

- **`flutter create --platforms=X .` side effect:** running this against `frontend/` (even scoped to one platform) regenerated `GeneratedPluginRegistrant`/ephemeral glue files inside the *other* existing placeholder platform folders (`android/`, `ios/`, `linux/`, `macos/`) too, not just the requested one. These were reverted (deleted) to keep those folders as pure placeholders per `docs/17_FOLDER_STRUCTURE.md` until each platform is actually being targeted. If you run `flutter create` again for a specific platform, check `git status` immediately after for unrelated platform folders picking up new files, and revert anything outside the platform you intended to touch.
- The Surfboard logo asset (`frontend/assets/logos/surfboard-payments-white-icon.svg`) is a **white-only** icon — it needs a dark/colored backdrop. See `core/widgets/branding/surfboard_logo.dart`'s two constructors (`.badge` / `.bare`) before using it anywhere new.
- **Root cause of all `flutter test`/`flutter build` failures on this machine, fully diagnosed:** Windows 11 **Smart App Control** is ON and enforced (registry `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` → `VerifiedAndReputablePolicyState = 1`), and it blocks `impellerc.exe` (Flutter's shader compiler) because that binary isn't cloud-reputation-recognized. Confirmed via Flutter's own source (`flutter_tools/lib/src/build_system/tools/shader_compiler.dart`) that this shader-compile step is **unconditional for every target platform** (android/ios/linux/windows/web/darwin) — there is no CLI flag or config to skip it. Smart App Control has **no per-app allow-list** (unlike Defender AV exclusions) and is **irreversible without a clean Windows reinstall** once turned off — so disabling it was presented as an option but not done unilaterally. User chose instead: set up Flutter inside WSL2, since Smart App Control is a Windows-native enforcement mechanism that doesn't apply to Linux binaries running under WSL2. This is the agreed path — see the "WSL2 setup" assumption above for current status.

- The git repository for this project is **independent** of the user's home-directory-rooted mega-repo (`C:/Users/velan`) that also tracks an unrelated "FinTwin AI" project with its own remote (`Velan0404/FinTwin-AI`) — this repo (`SurfPOS AI`) has its own `.git`, pushed to `Gopi7104/SurfPOS-AI`. Don't confuse the two if either comes up.
- Observed git history shows someone ran `git pull origin main` and switched between `velan`/`gopi` branches outside of this session between two of my turns — local branch state can change without my involvement; always re-check before assuming.
- `LICENSE`, Firebase project, Surfboard credentials, and Gemini API key are all real placeholders/TBDs right now, not oversights — don't treat their absence as a bug to silently fix.

## Future Ideas

_(Not decided, not scheduled — candidates for later, sourced from `docs/01_PROJECT_OVERVIEW.md § Future Scope` and conversation so far. Promote to [decision.md](decision.md) only once actually decided.)_

- Multi-store UI (schema already supports it — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-008`).
- Offline sale queueing for unreliable-connectivity checkout.
- Customer loyalty/CRM, supplier-facing portal, Flutter Web back-office.
- Predictive restocking / anomaly detection extensions to the AI insights engine.
- Multi-currency support beyond SEK, if the target market ever expands past Sweden.
