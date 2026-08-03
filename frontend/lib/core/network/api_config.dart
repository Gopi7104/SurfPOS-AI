import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_environment.dart';

/// Backend base URL — the single source of truth every [ApiClient] instance
/// reads from; never hardcoded inline at a call site. Full picture:
/// docs/23_ENVIRONMENT_CONFIGURATION.md.
///
/// This app never bakes a developer's personal machine/network IP into
/// source code. Resolution order, highest priority first:
///
///  1. `--dart-define=API_BASE_URL=...` — an explicit override. This is the
///     *only* way [AppEnvironment.staging]/[AppEnvironment.production]
///     builds get a URL (see [baseUrl] below) — CI supplies it at build
///     time, e.g. `flutter build apk --dart-define=APP_ENV=production
///     --dart-define=API_BASE_URL=https://api.surfpos.example`.
///  2. [AppEnvironment.development] only: `API_BASE_URL` from `frontend/.env`
///     (loaded by [initialize], via `flutter_dotenv`) — the day-to-day
///     development mechanism. `.env` is git-ignored and personal (see
///     `.env.example` for the template, which defaults to the deployed
///     Render backend — see docs/23_ENVIRONMENT_CONFIGURATION.md). Running
///     the backend locally instead (USB/Wi-Fi/emulator) is still supported —
///     just point this at the relevant local address.
///
/// If neither resolves, [baseUrl] throws rather than silently guessing an
/// address — a wrong-but-plausible-looking default is worse than a loud,
/// actionable error.
abstract final class ApiConfig {
  static const _dartDefineOverride = String.fromEnvironment('API_BASE_URL');

  static String? _resolved;

  /// Must be awaited once, before `runApp()` — see `main.dart`. Safe to call
  /// more than once (e.g. in tests); each call re-resolves from scratch.
  static Future<void> initialize(
      {AppEnvironment environment = AppEnvironment.development}) async {
    _resolved = null;

    if (_dartDefineOverride.isNotEmpty) {
      _resolved = _dartDefineOverride;
      return;
    }

    if (!environment.isDevelopment) {
      // Staging/production must always be explicit — see the class doc.
      return;
    }

    // `isOptional: true` — a missing/empty `.env` (e.g. a fresh clone before
    // the one-time `cp .env.example .env` setup step) is an expected state,
    // not an error; [baseUrl] below reports it clearly if nothing else set
    // API_BASE_URL either.
    await dotenv.load(fileName: '.env', isOptional: true);
    final fromEnvFile = dotenv.maybeGet('API_BASE_URL');
    if (fromEnvFile != null && fromEnvFile.isNotEmpty) {
      _resolved = fromEnvFile;
    }
  }

  /// The backend base URL resolved by [initialize]. Throws [StateError] if
  /// [initialize] hasn't run yet, or ran but found no configured URL — see
  /// the class doc for exactly how to fix each case.
  static String get baseUrl {
    final resolved = _resolved;
    if (resolved != null) return resolved;

    throw StateError(
      'No backend API_BASE_URL is configured for ${AppEnvironment.current.name}. '
      '${AppEnvironment.current.isDevelopment ? 'Copy frontend/.env.example to frontend/.env (defaults to the deployed Render backend), or set API_BASE_URL to a local address if running the backend locally, or run with --dart-define=API_BASE_URL=... for a one-off override.' : 'Staging/production builds must supply --dart-define=API_BASE_URL=https://your-backend.example — see docs/23_ENVIRONMENT_CONFIGURATION.md.'}',
    );
  }
}
