import '../models/settings_data.dart';

/// Seam between the Settings controllers and wherever preferences actually
/// live — local-storage-only for now (see [SettingsRepositoryImpl]'s
/// header comment), mirroring `InventoryRepository`/`CustomerRepository`'s
/// role. Every method's shape (read-the-whole-thing, write-the-whole-thing)
/// is simple enough that a future backend-backed implementation (a real
/// per-merchant settings endpoint) could replace this one without any
/// controller/widget change.
abstract class SettingsRepository {
  Future<SettingsData> loadSettings();

  Future<SettingsData> updateSettings(SettingsData data);

  /// Resets every preference this module owns back to defaults — "Reset
  /// Settings" in the Danger Zone. Never touches any other feature's data
  /// (see [SettingsRepositoryImpl]'s header comment).
  Future<SettingsData> resetToDefaults();

  /// The size, in bytes, of this module's own persisted JSON blob — "Storage
  /// Usage" in Backup & Sync. Deliberately scoped to only what this module
  /// owns, never another feature's storage.
  Future<int> storageUsageBytes();

  /// "Clear Cache" in the Danger Zone — same effect as [resetToDefaults]
  /// today (this module has no separate cache from its settings blob), kept
  /// as its own method so the two Danger Zone actions can diverge later
  /// without a signature change.
  Future<void> clearCache();
}
