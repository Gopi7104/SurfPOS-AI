/// Which backend environment this build talks to — selected once, at build
/// time, via `--dart-define=APP_ENV=development|staging|production`. Never
/// decided at runtime and never inferred from anything else, so a given
/// build's environment is always known ahead of time (e.g. in CI).
///
/// See docs/23_ENVIRONMENT_CONFIGURATION.md for the full picture, including
/// how this interacts with [ApiConfig]'s URL resolution.
enum AppEnvironment {
  development,
  staging,
  production;

  static const _dartDefineValue =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  /// Resolved once per process from `--dart-define=APP_ENV`. Falls back to
  /// [development] for any unrecognized value (including none supplied) —
  /// the safest default, since it never accidentally points a debug build at
  /// a real staging/production backend.
  static AppEnvironment get current {
    return AppEnvironment.values.firstWhere(
      (env) => env.name == _dartDefineValue,
      orElse: () => AppEnvironment.development,
    );
  }

  bool get isDevelopment => this == AppEnvironment.development;
}
