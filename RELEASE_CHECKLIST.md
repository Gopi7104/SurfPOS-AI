# Release Checklist

Run through this before every production deployment. See `DEPLOYMENT.md` for the commands behind
each step and `PRODUCTION_ENV.md` for the full env var reference.

## Pre-flight

- [ ] All required env vars set for the target environment (`PRODUCTION_ENV.md` § 1) — verify with
      `NODE_ENV=production node -e "require('./src/config')"` from `backend/`.
- [ ] `CORS_ALLOWED_ORIGINS` set to an explicit origin list (not the `*` default).
- [ ] `SURFBOARD_ENV=production` and real (non-sandbox) Surfboard credentials, if this is a real
      payments release.
- [ ] `SURFBOARD_ONLINE_STORE_WEBSHOP_URL`/`_TERMS_URL`/`_PRIVACY_URL` point at the merchant's real
      URLs — Surfboard's `onlineInfo` can only be set once per store, ever.
- [ ] No `.env`, `key.properties`, `.jks`/`.keystore`, or other secret file is staged for commit
      (`git status` — all should be git-ignored already).

## Backend

- [ ] `cd backend && npm test` passes.
- [ ] `npm run lint` and `npm run format:check` pass.
- [ ] `npm run build` (module-load sanity check) passes.
- [ ] `GET /health` returns `status: "ok"` with the expected `environment` and `version` once
      deployed.
- [ ] Render service env vars match `PRODUCTION_ENV.md` — no leftover sandbox/dev values.

## Frontend

- [ ] `cd frontend && flutter analyze` passes with no errors.
- [ ] `flutter test` passes.
- [ ] `pubspec.yaml` version bumped (`x.y.z+buildNumber`) since the last release.
- [ ] Release build succeeds:
      `flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=<prod backend URL>`
- [ ] If this is a real Play Store release: `key.properties` points at the real release keystore
      (not falling back to debug signing), and `applicationId` is the real package ID, not
      `com.example.surfpos_ai`.
- [ ] App icon renders correctly (`flutter_launcher_icons` output already committed under
      `android/app/src/main/res` and `ios/Runner/Assets.xcassets`).

## CI/CD

- [ ] `.github/workflows/backend.yml` is green on the release commit.
- [ ] `.github/workflows/frontend.yml` is green on the release commit.

## Post-deploy

- [ ] Hit `/health` on the live backend URL and confirm the response.
- [ ] Smoke-test one login + one read-only screen against the deployed backend from a release
      build (or the built APK).
- [ ] Confirm Surfboard webhook URL (`PUBLIC_BASE_URL` + webhook route) is reachable from the
      public internet, if this release depends on webhook delivery.
- [ ] Tag the release commit / update `CHANGELOG.md`.

## Explicitly out of scope for this checklist

No business logic, UI, payment flow, AI behavior, or database migration changes are covered here —
this checklist only guards infrastructure/deployment concerns.
