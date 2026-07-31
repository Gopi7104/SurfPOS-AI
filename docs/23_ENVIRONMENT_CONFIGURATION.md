# 23 — Frontend Environment Configuration

How the Flutter app decides which backend to talk to, across Development/Staging/Production, and
specifically how to stop re-editing source code every time your development machine's Wi-Fi
network (and therefore its LAN IP) changes.

## 1. The problem this replaces

Earlier, `frontend/lib/core/network/api_config.dart` had a real developer's LAN IP baked in as a
`defaultValue` on a `String.fromEnvironment('API_BASE_URL', ...)` constant. That IP is only valid
on the Wi-Fi network it was captured on — switch to a different office Wi-Fi, a mobile hotspot, or
just let your router hand out a new DHCP lease at home, and the app silently points at a dead
address. The only fix was editing that line of source and re-running.

**No IP address is hardcoded anywhere in the app now.** See § 4 for what changing networks looks
like today.

## 2. Two independent axes

These are separate concerns, each with its own mechanism:

- **Which environment** (`AppEnvironment`: `development` | `staging` | `production`) — a build-time
  choice, via `--dart-define=APP_ENV=...`. Defaults to `development` if not supplied.
- **Which backend URL** (`ApiConfig.baseUrl`) — resolved differently depending on the environment
  (§ 3). Every `ApiClient` (and therefore every repository/service in `lib/features/*`) reads this
  one value — there is exactly one place backend URLs are decided.

## 3. `ApiConfig.baseUrl` resolution order

1. **`--dart-define=API_BASE_URL=...`** — an explicit override. Always wins, in any environment.
   This is the *only* mechanism `staging`/`production` builds use.
2. **Development only:** the `API_BASE_URL` key in `frontend/.env`, loaded via `flutter_dotenv`.
   This is the day-to-day mechanism for local development — see § 4.
3. **Neither is set:** `ApiConfig.baseUrl` throws a `StateError` with an actionable message. The
   app never falls back to a guessed address.

`frontend/lib/core/config/app_environment.dart` (the `AppEnvironment` enum) and
`frontend/lib/core/network/api_config.dart` (`ApiConfig`) are the only two files involved — nothing
else duplicates this logic. Every repository takes an `ApiClient` via constructor injection (see
`frontend/lib/features/*/providers/*_providers.dart`), and every `ApiClient` falls back to
`ApiConfig.baseUrl` when no explicit `baseUrl` is passed — so wiring a new feature's repository
never requires touching URL configuration again.

## 4. Development workflow (the Wi-Fi-switching case)

One-time setup, per machine:

```bash
cd frontend
cp .env.example .env
```

Edit `frontend/.env` and set `API_BASE_URL` to wherever your backend is reachable:

| Target | `API_BASE_URL` |
|---|---|
| Android emulator | `http://10.0.2.2:4000` — a fixed alias the emulator maps to the host machine's loopback. **Never changes when you switch Wi-Fi networks** — prefer this for emulator testing. |
| iOS simulator | `http://localhost:4000` — the simulator shares the host's network stack. Also unaffected by Wi-Fi changes. |
| Physical device (Android/iOS) | `http://<your-machine's-current-LAN-IP>:4000` — **must** be on the same Wi-Fi network as your development machine. This is the one that changes when you switch networks. |

Finding your machine's current LAN IP:

```bash
# macOS
ipconfig getifaddr en0        # or en1, depending on your active adapter

# Linux
hostname -I

# Windows (PowerShell/cmd)
ipconfig                      # look for "IPv4 Address" under your active adapter
```

**Every time you switch Wi-Fi networks (office → mobile hotspot → home, etc.) and you're testing
on a physical device:** re-run the command above, update the one line in `frontend/.env`, then
hot-restart the app (not just hot-reload — `flutter_dotenv` reads the file once at startup). No
source code changes, no rebuild flags, no `--dart-define`.

`.env` is git-ignored (see root `.gitignore`) — it's personal to your machine, never shared or
committed. `.env.example` is the committed template every developer copies from.

### One-off override without touching `.env`

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
```

Useful for a quick test against a different backend without disturbing your usual `.env`.

## 5. Staging / Production

These never read `.env` — the backend URL is always supplied explicitly at build time (e.g. by
CI), which is the standard, secret-free way to point a release build at a known, fixed backend:

```bash
# Staging
flutter build apk --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.surfpos.example

# Production
flutter build apk --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.surfpos.example
```

If `APP_ENV` is `staging` or `production` and `API_BASE_URL` isn't supplied, `ApiConfig.baseUrl`
throws rather than silently trying to load a `.env` file that build should never depend on.

## 6. Verifying your setup

There's no dedicated command — the signal is simply that the app's first backend call succeeds
instead of throwing a connection error. If `ApiConfig.baseUrl` itself is misconfigured, the app
surfaces a clear `StateError` message (naming exactly which file/flag to fix) rather than a vague
network failure, the first time any screen tries to talk to the backend.

## 7. Related docs

- [14_DEVELOPER_GUIDE.md § 6–7](14_DEVELOPER_GUIDE.md#6-environment-variables) — backend
  environment variables and running backend + frontend together.
