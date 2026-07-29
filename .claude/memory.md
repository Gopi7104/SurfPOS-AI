# Working Memory

> Part of the `.claude/` knowledge base — read after [project.md](project.md), [projectStatus.md](projectStatus.md), and [decision.md](decision.md) (see [project.md § Read these files next](project.md#read-these-files-next)). This file is **temporary and disposable** — current focus, assumptions, reminders, and open questions. **Permanent architectural/technical decisions do not belong here — they belong in [decision.md](decision.md).** Prune this file as items resolve; it should stay short and current, not accumulate forever.

---

## Current Focus

- Just finished a full documentation realignment pass: Surfboard is now confirmed as the system of record for Merchant/Store/Device/Payment/Branding/Tips/Payment Methods (not just a payment processor), Firebase holds application data only, and the Flutter app talks only to the backend. Twelve docs fully rewritten, six lightly updated, four new docs added, old Phase 0/1/2/3 roadmap replaced entirely by a new 13-phase order. See [projectStatus.md § Completed](projectStatus.md#completed) for the full file list.
- **This was documentation-only — verified no file under `backend/src/`, `backend/tests/`, `.github/workflows/`, or `.husky/` was touched.** The user explicitly said to stop all feature development and wait for approval of the new documentation before writing any code.

## Current Assumptions

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
