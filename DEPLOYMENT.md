# Deployment Guide

How to run SurfPOS AI locally, and how to deploy the backend (Render) and frontend (Android APK)
to staging/production. This is the infrastructure-only entry point — see
`docs/23_ENVIRONMENT_CONFIGURATION.md` and `docs/14_DEVELOPER_GUIDE.md` for deeper background, and
`PRODUCTION_ENV.md` for the full environment variable reference.

## 1. Local development

```bash
# Backend
cd backend
cp .env.example .env      # fill in real values, or leave optional ones blank
npm install
npm run dev                # http://localhost:4000, http://127.0.0.1:4000/health

# Frontend (in a separate terminal)
cd frontend
cp .env.example .env       # defaults to USB development, see docs/23_ENVIRONMENT_CONFIGURATION.md
flutter pub get
frontend/scripts/run_usb.sh   # or `flutter run` directly
```

## 2. Backend deployment (Render)

This repo includes a Render Blueprint (`render.yaml`) that provisions a single web service from
`backend/`.

1. Push this branch/`main` to GitHub (Render deploys from a Git repo).
2. In the Render dashboard: **New → Blueprint**, point it at this repo. Render reads `render.yaml`
   and creates the `surfpos-ai-backend` service.
3. Fill in every `sync: false` variable in the dashboard (secrets — see `PRODUCTION_ENV.md` § 1–2
   for what each one needs). Render never stores these in the blueprint file.
4. `autoDeploy` is `false` in the blueprint on purpose. Trigger the first deploy manually from the
   Render dashboard once the env vars are set, review the build/deploy logs, then hit
   `https://<your-service>.onrender.com/health` to confirm `{"status":"ok", ...}`.
5. Once you're comfortable, flip `autoDeploy: true` in `render.yaml` (or leave it manual — your
   call) for subsequent deploys.

No Dockerfile is needed — Render's native Node runtime runs `npm ci` then `npm start`
(`node src/server.js`), which already binds `HOST`/`PORT` correctly for a PaaS (see
`backend/src/server.js`, `backend/src/config/index.js`).

### Health check

`GET /health` (public, outside the rate limiter) returns:

```json
{ "success": true, "data": { "status": "ok", "uptimeSeconds": 123, "timestamp": "...", "version": "0.1.0", "environment": "production" } }
```

Render's blueprint points `healthCheckPath` at this route.

## 3. Frontend deployment (Android)

### Android release signing

`frontend/android/app/build.gradle.kts` looks for `frontend/android/key.properties` (git-ignored).
If it's absent, release builds fall back to the debug keystore (fine for CI/local testing, **not**
fine for a Play Store upload).

To sign for real:

```bash
cd frontend/android
cp key.properties.example key.properties
# edit key.properties with your real keystore path + passwords
```

Generate a keystore first if you don't have one (see the comment in `key.properties.example`).
Keep the `.jks`/`.keystore` file and `key.properties` out of git — both are already git-ignored.

### Building

```bash
cd frontend
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://<your-render-service>.onrender.com
```

Output: `frontend/build/app/outputs/flutter-apk/app-release.apk`.

For a Play Store upload, build an app bundle instead:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://<your-render-service>.onrender.com
```

### Before a real Play Store release

- `applicationId`/`namespace` in `frontend/android/app/build.gradle.kts` is still the Flutter
  template default (`com.example.surfpos_ai`) — change it to your real package ID first; it cannot
  be changed after the first Play Store upload.
- App icons are generated via `flutter_launcher_icons` (`dart run flutter_launcher_icons`) from
  `assets/images/logo/surfpos_logo.png` — already configured in `pubspec.yaml`.
- There's no launch/splash screen package configured yet (`flutter_native_splash` or equivalent) —
  out of scope for this infra pass; add it separately if a branded splash screen is wanted.

## 4. CI/CD

Two GitHub Actions workflows, both verification-only (they never deploy or publish anything):

- `.github/workflows/backend.yml` — `npm ci`, lint, format check, test, build check.
- `.github/workflows/frontend.yml` — `flutter analyze`, `flutter test`, `flutter build apk --release`.

Both run on push to `main` and on pull requests, scoped by path filters so a frontend-only change
doesn't re-run the backend job and vice versa.

## 5. Firebase

Firebase config is verify-only for this phase — nothing was changed:

- `firebase/database.rules.json` and `firebase/storage.rules` are both deny-all placeholders. This
  is intentional and correct as-is: the Flutter app never talks to Realtime Database or Storage
  directly (no `firebase_database`/`firebase_storage` client dependency in `pubspec.yaml`) — all
  access goes through the backend's Firebase Admin SDK (`backend/src/firebase/admin.js`), which
  bypasses client security rules entirely. Revisit only if a client ever needs direct DB/Storage
  access.
- Firebase Auth is the one client-side Firebase feature in use (`firebase_auth` in `pubspec.yaml`),
  backed by `frontend/android/app/google-services.json` (already committed — see § 6).
- No `frontend/ios/Runner/GoogleService-Info.plist` exists yet — iOS Firebase Auth isn't configured.
  Not a blocker for an Android-only release; add it before shipping an iOS build.
- Deploy rule/index changes (if any are ever made) with:
  ```bash
  cd firebase && firebase deploy --only database,storage
  ```

## 6. Security notes

- `frontend/android/app/google-services.json` is committed to the repo and contains the **real**
  `surfpos-ai` Firebase project's client config. This is expected/acceptable — Google documents
  this file as safe to ship inside a client app (it's not a secret; Firebase Security Rules are the
  actual access boundary) — but it does mean this repo currently only has one Firebase project
  wired up for Android, not a separate one per environment. Provision separate Firebase projects
  per environment (see `docs/14_DEVELOPER_GUIDE.md` § 8) before treating staging and production as
  fully isolated.
- No real secrets are committed anywhere else: `backend/.env`, `frontend/.env`, and any
  `key.properties`/`.jks`/`.keystore` are all git-ignored (see root `.gitignore`); only the
  `.env.example` templates and `key.properties.example` are tracked.
- Set `CORS_ALLOWED_ORIGINS` to an explicit origin list in every real deployment — see
  `PRODUCTION_ENV.md`.

## 7. Related docs

- `PRODUCTION_ENV.md` — full environment variable reference.
- `RELEASE_CHECKLIST.md` — pre-release checklist.
- `docs/23_ENVIRONMENT_CONFIGURATION.md` — frontend backend-URL resolution in depth.
- `docs/14_DEVELOPER_GUIDE.md` — day-to-day dev setup.
