/// Backend base URL — never hardcoded inline at a call site (see
/// docs/07_CODING_RULES.md § 11). Set at build/run time, e.g.:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.23:4000
///
/// Defaults to the backend's current LAN IP (see backend/.env HOST=0.0.0.0,
/// which makes it listen on every interface, not just loopback) so a
/// physical device on the same Wi-Fi network can reach it directly with no
/// adb reverse/port-forwarding needed. This IP is only valid on the network
/// it was captured on and may change on a different network or after a
/// router DHCP renewal — override with --dart-define when it does.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.31.99.94:4000',
  );
}
