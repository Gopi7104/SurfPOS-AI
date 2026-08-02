# Production Environment Variables

Authoritative list of every environment variable the backend reads (see
`backend/src/config/index.js`), what it's for, and whether it's required for a production boot.
Frontend build-time values are covered in § 3.

Never commit real values. `backend/.env.example` is the committed, secret-free template.

## 1. Backend — required in production

Boot fails immediately (`process.exit(1)`) if any of these are missing and `NODE_ENV=production`:

| Variable | Purpose |
|---|---|
| `FIREBASE_PROJECT_ID` | Firebase Admin SDK service account — project ID |
| `FIREBASE_CLIENT_EMAIL` | Firebase Admin SDK service account — client email |
| `FIREBASE_PRIVATE_KEY` | Firebase Admin SDK service account — private key (keep `\n` escapes; `config/index.js` un-escapes them) |
| `FIREBASE_DATABASE_URL` | Realtime Database URL |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket name |
| `OPENROUTER_API_KEY` | SurfAI's AI provider (OpenRouter) |
| `SURFBOARD_API_KEY` | Surfboard Payments API credential |
| `SURFBOARD_API_SECRET` | Surfboard Payments API credential |
| `SURFBOARD_WEBHOOK_SECRET` | Verifies incoming Surfboard webhook signatures |

## 2. Backend — optional / defaulted

| Variable | Default | Notes |
|---|---|---|
| `NODE_ENV` | `development` | Set to `production` on Render. There is no separate `staging` value — a staging deployment is just another `NODE_ENV=production` instance with its own Firebase project and Surfboard sandbox credentials (see § 4). |
| `PORT` | `4000` | Render injects its own `PORT`; the app already reads `process.env.PORT`, so no action needed. |
| `HOST` | `0.0.0.0` | Correct for Render/any PaaS — binds all interfaces. |
| `LOG_LEVEL` | `info` | `debug`/`trace` are noisy — keep `info` or `warn` in production. |
| `CORS_ALLOWED_ORIGINS` | `*` | **Set an explicit comma-separated origin list in production** (e.g. `https://app.surfpos.example`) rather than leaving the wildcard default. |
| `PUBLIC_BASE_URL` | unset | This backend's own public HTTPS URL (Render gives you one, e.g. `https://surfpos-ai-backend.onrender.com`). Needed for Surfboard redirect/webhook URLs — see `docs/23_ENVIRONMENT_CONFIGURATION.md`. |
| `OPENROUTER_BASE_URL` | `https://openrouter.ai/api/v1` | Only override for a proxy/self-hosted gateway. |
| `DEFAULT_MODEL` | `openai/gpt-5-mini` | SurfAI's default model. |
| `OCR_PROVIDER_API_KEY` | unset | Only needed once the OCR-backed AI feature is live. |
| `SURFBOARD_ENV` | `sandbox` | Set to `production` for real payments. |
| `SURFBOARD_AUTH_STRATEGY` | `api_key_secret` | Confirmed correct strategy — see `docs/08_ARCHITECTURE_DECISIONS.md` ADR-025. |
| `SURFBOARD_BEARER_TOKEN` | unset | Only used when `SURFBOARD_AUTH_STRATEGY=bearer`. |
| `SURFBOARD_PARTNER_ID`, `SURFBOARD_API_URL`, `SURFBOARD_SECRET_KEY` | unset | Only for a partner/white-label gateway deployment. |
| `SURFBOARD_ONLINE_STORE_WEBSHOP_URL` / `_TERMS_URL` / `_PRIVACY_URL` | `https://example.com...` | **Must be your merchant's real URLs before processing a real payment** — Surfboard's `onlineInfo` can only be set once per store, ever. |

## 3. Frontend — build-time values (never `.env` in release builds)

Set via `--dart-define` at build time — see `docs/23_ENVIRONMENT_CONFIGURATION.md` for the full
resolution order.

| Flag | Example (production) |
|---|---|
| `APP_ENV` | `production` |
| `API_BASE_URL` | `https://surfpos-ai-backend.onrender.com` |

```bash
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://surfpos-ai-backend.onrender.com
```

Android signing is a separate mechanism (`frontend/android/key.properties`, git-ignored) — see
`DEPLOYMENT.md` § Android release signing.

## 4. Staging

There's no code-level "staging" mode on the backend — a staging deployment is:

- A second Render service (or a second `render.yaml` blueprint), `NODE_ENV=production`, pointed at
  a **separate Firebase project** and **Surfboard sandbox** credentials.
- A frontend build with `--dart-define=APP_ENV=staging --dart-define=API_BASE_URL=<staging backend URL>`.

This keeps staging behaviorally identical to production (same validation, same security headers)
while fully isolating its data and payment credentials from the real thing.

## 5. Verifying before deploy

```bash
cd backend
NODE_ENV=production node -e "require('./src/config')"
```

Exits non-zero with a clear `Missing required production environment variables` log line if
anything in § 1 is missing — run this against your real `.env`/Render env before deploying.
