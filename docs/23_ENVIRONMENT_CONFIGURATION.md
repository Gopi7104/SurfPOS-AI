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

## 4. Development workflow

One-time setup, per machine:

```bash
cd frontend
cp .env.example .env
```

`.env` is git-ignored (see root `.gitignore`) — it's personal to your machine, never shared or
committed. `.env.example` is the committed template every developer copies from, and it defaults
`API_BASE_URL` to the USB setup below (§ 4a) — the recommended default for this project.

Four ways to run the app in development, depending on what you're testing on:

| Target | `API_BASE_URL` | Notes |
|---|---|---|
| **Physical Android device via USB (default)** | `http://127.0.0.1:4000` | See § 4a. Immune to Wi-Fi/LAN changes. |
| Physical device via Wi-Fi | `http://<your-machine's-current-LAN-IP>:4000` | See § 4b. Changes every time you switch networks. |
| Android emulator | `http://10.0.2.2:4000` | See § 4c. Fixed alias, never changes. |
| iOS simulator | `http://localhost:4000` | Simulator shares the host's network stack — unaffected by Wi-Fi changes. |

### 4a. USB development (recommended default)

A physical Android device connected over USB, using `adb reverse` to forward a port on the device
to the same port on your development machine — so the app can always reach the backend at
`127.0.0.1:4000`, regardless of which Wi-Fi network (if any) either machine is on.

One-time per device connection (or use the script below, which does this automatically):

```bash
adb reverse tcp:4000 tcp:4000
```

This tells the device: "requests to my own `127.0.0.1:4000` should be forwarded, over the USB
connection, to `127.0.0.1:4000` on the host." Since `frontend/.env.example` already defaults
`API_BASE_URL=http://127.0.0.1:4000`, no `.env` edits are needed — this is the zero-maintenance
path once set up.

Recommended: run the app via the provided script, which sets up the port forward for you every
time before launching:

```bash
frontend/scripts/run_usb.sh
```

It checks that `adb` is on `PATH` and that a device is attached, runs `adb reverse tcp:4000
tcp:4000`, then runs `flutter run` (passing through any extra args, e.g. `frontend/scripts/run_usb.sh -d <device-id>`).

Caveats:
- `adb reverse` only lasts for the current USB connection/adb session — unplugging the device (or
  restarting adb, e.g. `adb kill-server`) clears it. Re-run the script (or the raw command) after
  reconnecting.
- Android only — `adb reverse` is an Android Debug Bridge feature. iOS has no equivalent; use the
  iOS simulator (unaffected by Wi-Fi changes already) or Wi-Fi development (§ 4b) for a physical
  iPhone.
- If you also need the emulator or a Wi-Fi device reachable at the same time, `adb reverse` doesn't
  conflict with anything — it only affects the specific USB-attached device it was run against.

### 4b. Wi-Fi development (wireless physical device)

Still fully supported — useful when you can't plug in via USB, or are testing on iOS. Edit
`frontend/.env` and set:

```
API_BASE_URL=http://<your-machine's-current-LAN-IP>:4000
```

Finding your machine's current LAN IP:

```bash
# macOS
ipconfig getifaddr en0        # or en1, depending on your active adapter

# Linux
hostname -I

# Windows (PowerShell/cmd)
ipconfig                      # look for "IPv4 Address" under your active adapter
```

The device **must** be on the same Wi-Fi network as your development machine. **Every time you
switch Wi-Fi networks** (office → mobile hotspot → home, etc.), re-run the command above, update
the one line in `frontend/.env`, then hot-restart the app (not just hot-reload —
`flutter_dotenv` reads the file once at startup). No source code changes, no rebuild flags, no
`--dart-define`. This is the LAN-IP-churn problem that USB development (§ 4a) avoids entirely.

### 4c. Emulator/simulator development

Set `frontend/.env` to the fixed alias for whichever emulator/simulator you're using (see the table
in § 4) and run `flutter run` normally — no `adb reverse`, no LAN IP, nothing that changes between
sessions.

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

There's no dedicated command for Wi-Fi/emulator setups — the signal is simply that the app's first
backend call succeeds instead of throwing a connection error. If `ApiConfig.baseUrl` itself is
misconfigured, the app surfaces a clear `StateError` message (naming exactly which file/flag to
fix) rather than a vague network failure, the first time any screen tries to talk to the backend.

For USB development (§ 4a) specifically, three things need to be true — check them in order if the
app can't reach the backend:

```bash
# 1. adb sees your device
adb devices
#    List of devices attached
#    <serial>    device          <- must say "device", not "unauthorized" or "offline"

# 2. the port forward is active
adb reverse --list
#    host-serial <serial> forward tcp:4000 tcp:4000

# 3. the backend is actually listening and reachable from the host itself
curl http://127.0.0.1:4000/health
#    {"status":"ok", ...}
```

If (1) fails, reconnect the USB cable and accept the RSA fingerprint prompt on the device. If (2)
is empty, re-run `frontend/scripts/run_usb.sh` or `adb reverse tcp:4000 tcp:4000` directly — the
forward is cleared on disconnect/`adb kill-server`. If (3) fails, start the backend
(`cd backend && npm run dev`) before launching the app.

## 7. Related docs

- [14_DEVELOPER_GUIDE.md § 6–7](14_DEVELOPER_GUIDE.md#6-environment-variables) — backend
  environment variables and running backend + frontend together.
