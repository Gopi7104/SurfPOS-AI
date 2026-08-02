import 'package:flutter/material.dart' show ThemeMode;

/// Seam for the app's light/dark/system theme preference — deliberately
/// its own small repository (per the Phase 7 brief's explicit
/// "Repositories: ... ThemeRepository" split), not folded into
/// [SettingsRepository]. Unlike every other Settings preference, this one
/// is **not** scoped to a Firebase uid: [SurfPosApp] must be able to read
/// it before Splash even knows whether anyone is signed in (Login/Splash
/// render before the Settings tab is ever reachable), and a device's
/// light/dark preference is inherently a device-level choice, not
/// per-merchant-account data — same reasoning `AppEnvironment`/`ApiConfig`
/// already apply to being global rather than uid-scoped.
abstract class ThemeRepository {
  Future<ThemeMode> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode mode);
}
