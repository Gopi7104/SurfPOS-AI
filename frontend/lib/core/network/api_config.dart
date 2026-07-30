/// Backend base URL — never hardcoded inline at a call site (see
/// docs/07_CODING_RULES.md § 11). Set at build/run time, e.g.:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:4000
///
/// Defaults to the Android emulator's host-loopback address. For a physical
/// device connected over USB, forward the port instead of guessing a LAN IP:
///
///   adb reverse tcp:4000 tcp:4000
///
/// which makes `http://localhost:4000` (or 10.0.2.2, harmlessly) reachable
/// from the device. iOS simulator/desktop builds should use
/// `--dart-define=API_BASE_URL=http://localhost:4000` directly.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
}
