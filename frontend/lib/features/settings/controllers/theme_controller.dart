import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';

/// The app's light/dark/system theme preference — not a `.family` provider
/// (see [ThemeRepository]'s header comment for why this is deliberately
/// not uid-scoped). [SurfPosApp] watches this directly to set
/// `MaterialApp.themeMode`.
class ThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() {
    return ref.read(themeRepositoryProvider).loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await ref.read(themeRepositoryProvider).saveThemeMode(mode);
  }
}
