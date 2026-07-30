# Working Memory

> Part of the `.claude/` knowledge base — read after [project.md](project.md), [projectStatus.md](projectStatus.md), and [decision.md](decision.md) (see [project.md § Read these files next](project.md#read-these-files-next)). This file is **temporary and disposable** — current focus, assumptions, reminders, and open questions. **Permanent architectural/technical decisions do not belong here — they belong in [decision.md](decision.md).** Prune this file as items resolve; it should stay short and current, not accumulate forever.

---

## Current Focus

**Frontend UI track:**
- Building the premium Flutter UI per the "Senior Flutter UI/UX Engineer" design brief: full custom design system (done) + 26 screens, one at a time (Splash done, 25 to go — see [projectStatus.md](projectStatus.md)).
- Just finished a full documentation realignment pass: Surfboard is now confirmed as the system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods (not just a payment processor), Firebase holds application data only, and the Flutter app talks only to the backend. Twelve docs fully rewritten, six lightly updated, four new docs added, old Phase 0/1/2/3 roadmap replaced entirely by a new 13-phase order. See [projectStatus.md § Completed](projectStatus.md#completed) for the full file list.
- **This was documentation-only — verified no file under `backend/src/`, `backend/tests/`, `.github/workflows/`, or `.husky/` was touched.** The user explicitly said to stop all feature development and wait for approval of the new documentation before writing any code.

Building the premium Flutter UI per the "Senior Flutter UI/UX Engineer" design brief: full custom design system (done) + 26 screens, one at a time (Splash done, 25 to go — see [projectStatus.md](projectStatus.md)).
- Next screen up: **Login**.
- The design system + widget library is verified clean (`flutter analyze`: 0 issues — errors, warnings, infos, and lints all zero, confirmed after fixing 7 `prefer_const_constructors`/`prefer_const_literals_to_create_immutables` infos in `skeleton_list.dart`). `flutter test` has passed (3/3) on a confirmed run, but also failed once on the same `impellerc.exe` Application Control block seen with `flutter build web` (release) — which has failed consistently on every attempt (2/2). See `projectStatus.md § Known Issues #5` for the full nuance: don't assume a single passing test run means it's reliable, and don't assume a passing test run implies a release build will also succeed on this machine.
- **A mandatory verification workflow is now in force for every task** (format → analyze-until-clean → test → build, then a fixed-format report) — see `.claude/workflow.md § Definition of Done` and `.claude/commands.md`. Follow it before considering any task complete, starting now


## Current Assumptions

**Frontend UI track:**
- Documentation/structure is complete project-wide, but **the frontend now has real code**: full design system + widget library, plus Splash (1/26 screens). Backend/Firebase remain entirely placeholder. Don't assume any file under `backend/src/` etc. is real, but do assume `frontend/lib/app/themes/` and `frontend/lib/core/widgets/` are real and should be reused, not recreated.
- **WSL2 setup is agreed but NOT started.** The user chose "set up Flutter inside WSL2" as the fix for the Windows Smart App Control block (see Temporary Notes below), but as of the last check, `wsl --status` still reports "The Windows Subsystem for Linux is not installed" — the user has not yet run `wsl --install` as Administrator + restarted. Do not assume WSL exists; check `wsl --status` fresh each time this comes up before proceeding with Flutter/Android SDK setup inside it.
- Sweden/SEK is the **current, correct** target market per [decision.md § D-010](decision.md#d-010--sweden-sek-selected-instead-of-inr) — but several `/docs` files still contain India/INR examples. Treat those specific examples as stale, not the rest of the surrounding document.
- Riverpod + `go_router` is the **proposed** (not yet formally confirmed) Flutter state-management/navigation choice — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-007`, Status: Proposed. Don't treat it as settled without checking that ADR's current status first.
- The exact Surfboard Payments API surface is unconfirmed against official docs — everything in `docs/15_SURFBOARD_INTEGRATION.md` is a pattern to verify, not a verified fact.

**Backend/docs track:**
- Just finished a full documentation realignment pass: Surfboard is now confirmed as the system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods (not just a payment processor), Firebase holds application data only, and the Flutter app talks only to the backend. Twelve docs fully rewritten, six lightly updated, four new docs added, old Phase 0/1/2/3 roadmap replaced entirely by a new 13-phase order. See [projectStatus.md § Completed](projectStatus.md#completed) for the full file list.
- **This was documentation-only — verified no file under `backend/src/`, `backend/tests/`, `.github/workflows/`, or `.husky/` was touched.** The user explicitly said to stop all feature development and wait for approval of the new documentation before writing any code.

- Backend foundational + infrastructure code (`backend/src/{config,utils,firebase,middleware,routes,controllers,services,constants,types,integrations}`, `app.js`, `server.js`, lint/format/test/CI tooling) is real. Everything business-domain — `frontend/lib/`, top-level `firebase/`, and every backend module under `src/modules/` — is still placeholder-only.
- **The most important assumption to get right now:** `merchants/{merchantId}`, `stores/{storeId}`, and `payments/{paymentId}` are **not** Firebase nodes — they never were implemented in code, and the docs describing them as Firebase nodes were wrong and have been corrected. Surfboard owns that data; it's fetched live through `src/integrations/surfboard/`. See [decision.md § D-016](decision.md#d-016--surfboard-is-the-system-of-record-for-merchant-store-device-payment-branding-tips-and-payment-methods).
- `src/integrations/<provider>/` (raw third-party HTTP clients) and `src/modules/<provider>/` (business/orchestration logic) are separate folders — see [decision.md § D-015](decision.md#d-015--srcintegrations-vs-srcmodules-split). This pass further split `modules/surfboard/` into `modules/{merchant,store,device,payments,branding}/`, one per Surfboard-owned entity — see [D-018](decision.md#d-018--surfboard-domain-module-split-tipspayment-methods-folded-in-not-standalone).
- `auth.middleware.js` verifies the Firebase ID token only; it does not yet fetch `merchantId`/`role` from `users/{uid}`. Don't assume `req.user.merchantId` or `req.user.role` are populated anywhere yet.
- Riverpod + `go_router` is still **Proposed**, not Accepted — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-007`.
- The exact Surfboard wire-level API surface (endpoint paths, field names, auth scheme) is still unconfirmed — only the *ownership model* is now confirmed. Everything in `docs/15_SURFBOARD_INTEGRATION.md`/`docs/19_SURFBOARD_WORKFLOWS.md` describing specific fields is illustrative, not verified.
- Real-time client strategy (how the Flutter app gets live updates now that it can't listen to Firebase directly) is a **new, genuinely unresolved** open item — don't assume polling or WebSockets without it being decided.

## Important Reminders

- **Never commit or push git changes without being explicitly asked.**
- **Do not write any application code — not even Phase 2 (Surfboard Client SDK) — until the user explicitly approves the realigned documentation.** This was the explicit closing instruction of this pass.
- **Never let a Firebase field duplicate a Surfboard-owned fact.** This is the single highest-value rule from this pass — before adding any new Firebase field, check [docs/20_DOMAIN_MODEL.md § 1](../docs/20_DOMAIN_MODEL.md#1-the-ownership-principle).
- When updating any fact that appears in multiple docs, search for all occurrences rather than fixing the first one found — this project has hit that gap twice now (`mobile/`→`frontend/`, and this Surfboard realignment touching 18 files).
- Always check `git status` and current branch before assuming what's on disk — branches in this repo (`main`, `velan`, `gopi`) have diverged and reconverged outside of a formal PR process at least once already.

## Pending Questions

_(For the user/project owner — surface these rather than guessing when they become relevant.)_

- Which OCR provider: on-device (e.g. ML Kit) or a cloud OCR API? (Blocks Phase 13 AI work.)
- **New:** real-time client strategy — polling vs. a backend push/streaming channel (WebSocket/SSE) — now that the Flutter app can't listen to Firebase directly? (Blocks Phase 8 Billing / Phase 12 Analytics.)
- What license will this project use? (`LICENSE` at repo root is currently a placeholder.)
- What's the actual relationship/roles between Velan and Gopi, and the intended branch/merge strategy between `main`, `velan`, and `gopi`? (See [workflow.md § Branch Strategy](workflow.md#branch-strategy).)
- Is Riverpod + `go_router` confirmed, or still open for debate?
- Are Surfboard sandbox credentials available yet, and is there official Surfboard API documentation to confirm the wire-level integration details against? (The *ownership model* is now confirmed regardless — see Current Assumptions above.)

## Temporary Notes

- **`flutter create --platforms=X .` side effect:** running this against `frontend/` (even scoped to one platform) regenerated `GeneratedPluginRegistrant`/ephemeral glue files inside the *other* existing placeholder platform folders (`android/`, `ios/`, `linux/`, `macos/`) too, not just the requested one. These were reverted (deleted) to keep those folders as pure placeholders per `docs/17_FOLDER_STRUCTURE.md` until each platform is actually being targeted. If you run `flutter create` again for a specific platform, check `git status` immediately after for unrelated platform folders picking up new files, and revert anything outside the platform you intended to touch.
- The Surfboard logo asset (`frontend/assets/logos/surfboard-payments-white-icon.svg`) is a **white-only** icon — it needs a dark/colored backdrop. See `core/widgets/branding/surfboard_logo.dart`'s two constructors (`.badge` / `.bare`) before using it anywhere new.
- **Root cause of all `flutter test`/`flutter build` failures on this machine, fully diagnosed:** Windows 11 **Smart App Control** is ON and enforced (registry `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` → `VerifiedAndReputablePolicyState = 1`), and it blocks `impellerc.exe` (Flutter's shader compiler) because that binary isn't cloud-reputation-recognized. Confirmed via Flutter's own source (`flutter_tools/lib/src/build_system/tools/shader_compiler.dart`) that this shader-compile step is **unconditional for every target platform** (android/ios/linux/windows/web/darwin) — there is no CLI flag or config to skip it. Smart App Control has **no per-app allow-list** (unlike Defender AV exclusions) and is **irreversible without a clean Windows reinstall** once turned off — so disabling it was presented as an option but not done unilaterally. User chose instead: set up Flutter inside WSL2, since Smart App Control is a Windows-native enforcement mechanism that doesn't apply to Linux binaries running under WSL2. This is the agreed path — see the "WSL2 setup" assumption above for current status.

- The git repository for this project is **independent** of the user's home-directory-rooted mega-repo (`C:/Users/velan`) that also tracks an unrelated "FinTwin AI" project with its own remote (`Velan0404/FinTwin-AI`) — this repo (`SurfPOS AI`) has its own `.git`, pushed to `Gopi7104/SurfPOS-AI`. Don't confuse the two if either comes up.
- Observed git history shows someone ran `git pull origin main` and switched between `velan`/`gopi` branches outside of this session between two of my turns — local branch state can change without my involvement; always re-check before assuming.
- `LICENSE`, Firebase project, Surfboard credentials, and Gemini API key are all real placeholders/TBDs right now, not oversights — don't treat their absence as a bug to silently fix.
- `npm audit` on `backend/` shows moderate/high advisories entirely inside `firebase-admin`'s own transitive Google Cloud client deps (`google-gax`/`gaxios`/`gcp-metadata`/`uuid`), even at the latest `firebase-admin@14.2.0` — not actionable from this repo right now, re-check next time `firebase-admin` is bumped.

## Future Ideas

_(Not decided, not scheduled — candidates for later, sourced from `docs/01_PROJECT_OVERVIEW.md § Future Scope` and conversation so far. Promote to [decision.md](decision.md) only once actually decided.)_

- Multi-store UI (schema already supports it — see `docs/08_ARCHITECTURE_DECISIONS.md § ADR-008`).
- Offline sale queueing for unreliable-connectivity checkout.
- Customer loyalty/CRM, supplier-facing portal, Flutter Web back-office.
- Predictive restocking / anomaly detection extensions to the AI insights engine.
- Multi-currency support beyond SEK, if the target market ever expands past Sweden.
