enum ServiceStatus {
  connected,
  disconnected,
  unknown;

  String get label => switch (this) {
        ServiceStatus.connected => 'Connected',
        ServiceStatus.disconnected => 'Disconnected',
        ServiceStatus.unknown => 'Unknown',
      };
}

/// Everything the Payment section's status cards and the Developer
/// section need — assembled by [DiagnosticsRepository] entirely from
/// already-live data this app has (a real `/health` call, `ApiConfig`/
/// `AppEnvironment`, and read-only reuse of Dashboard's/Authentication's
/// already-fetched provider values) — see [DiagnosticsRepository]'s
/// header comment for exactly what backs each field.
class DiagnosticsSnapshot {
  const DiagnosticsSnapshot({
    required this.backendStatus,
    this.backendResponseTime,
    required this.surfboardStatus,
    required this.firebaseStatus,
    required this.environment,
    this.apiBaseUrl,
    this.merchantId,
    this.storeId,
    this.merchantStatus,
    this.storeStatus,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceDescription,
  });

  final ServiceStatus backendStatus;
  final Duration? backendResponseTime;
  final ServiceStatus surfboardStatus;
  final ServiceStatus firebaseStatus;

  final String environment;
  final String? apiBaseUrl;

  final String? merchantId;
  final String? storeId;
  final String? merchantStatus;
  final String? storeStatus;

  final String appVersion;
  final String buildNumber;
  final String deviceDescription;
}
