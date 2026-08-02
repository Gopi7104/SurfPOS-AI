import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/diagnostics_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/diagnostics_snapshot.dart';
import '../models/settings_data.dart';
import '../repositories/diagnostics_repository.dart';
import '../repositories/diagnostics_repository_impl.dart';
import '../repositories/printer_repository.dart';
import '../repositories/printer_repository_impl.dart';
import '../repositories/settings_local_storage.dart';
import '../repositories/settings_repository.dart';
import '../repositories/settings_repository_impl.dart';
import '../repositories/theme_repository.dart';
import '../repositories/theme_repository_impl.dart';

/// DI wiring for the Settings feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3), reusing the
/// authentication feature's shared [secureStorageServiceProvider]/
/// [apiClientProvider] rather than redeclaring them, matching the
/// established cross-feature-provider-reuse convention.

final settingsLocalStorageProvider =
    Provider.family<SettingsLocalStorage, String>((ref, uid) {
  return SettingsLocalStorage(ref.watch(secureStorageServiceProvider), uid);
});

final settingsRepositoryProvider =
    Provider.family<SettingsRepository, String>((ref, uid) {
  return SettingsRepositoryImpl(
      localStorage: ref.watch(settingsLocalStorageProvider(uid)));
});

/// Not a `.family` — see [ThemeRepository]'s header comment.
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  return ThemeRepositoryImpl(ref.watch(secureStorageServiceProvider));
});

final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepositoryImpl();
});

final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  return DiagnosticsRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// Keyed by Firebase uid — never a global singleton (cross-user isolation,
/// see docs/22_DEVELOPMENT_ROADMAP.md). `autoDispose` frees a previous
/// user's loaded settings the moment nothing watches it anymore.
final settingsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<SettingsController, SettingsData, String>(
  SettingsController.new,
);

/// Not a `.family` — see [ThemeController]'s header comment. Not
/// `autoDispose` either: the app-wide `MaterialApp` in `app.dart` watches
/// this for the entire app's lifetime, so it must never be disposed just
/// because Settings' own screen isn't currently mounted.
final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

final diagnosticsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DiagnosticsController, DiagnosticsSnapshot, String>(
  DiagnosticsController.new,
);

/// A one-shot check of [PrinterRepository.isConnected] for the Printer
/// section's preview card on Settings Home — `autoDispose`, re-evaluated
/// each time the section is (re)built rather than held as long-lived
/// state, since nothing in this app pushes printer-connection-changed
/// events.
final printerConnectionProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(printerRepositoryProvider).isConnected();
});

/// "Storage Usage" in Backup & Sync — see [SettingsRepository
/// .storageUsageBytes]'s header comment for scope.
final settingsStorageUsageProvider =
    FutureProvider.autoDispose.family<int, String>((ref, uid) {
  return ref.watch(settingsRepositoryProvider(uid)).storageUsageBytes();
});
