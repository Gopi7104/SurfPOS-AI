#!/usr/bin/env bash
# Runs the Flutter app against a USB-connected Android device.
#
# Sets up `adb reverse tcp:4000 tcp:4000` first, so the device's own
# 127.0.0.1:4000 forwards to the backend running on the host machine's
# 127.0.0.1:4000 — no LAN IP, no Wi-Fi dependency. See
# docs/23_ENVIRONMENT_CONFIGURATION.md § 4a.
#
# Usage: frontend/scripts/run_usb.sh [extra flutter run args]
set -euo pipefail

if ! command -v adb >/dev/null 2>&1; then
  echo "error: adb not found on PATH. Install Android platform-tools (or add it to PATH)." >&2
  exit 1
fi

DEVICE_COUNT=$(adb devices | tail -n +2 | grep -c "[[:space:]]device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
  echo "error: no Android device detected via adb." >&2
  echo "Connect your phone via USB, enable USB debugging, and accept the RSA fingerprint prompt." >&2
  exit 1
fi

echo "[run_usb] adb reverse tcp:4000 tcp:4000"
adb reverse tcp:4000 tcp:4000

echo "[run_usb] flutter run"
cd "$(dirname "$0")/.."
exec flutter run "$@"
