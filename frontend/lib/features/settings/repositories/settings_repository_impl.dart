import 'dart:convert';

import '../models/settings_data.dart';
import 'settings_local_storage.dart';
import 'settings_repository.dart';

/// Reads/writes the whole [SettingsData] blob via [SettingsLocalStorage] —
/// no `/settings` backend endpoint exists yet (Phase 7 scope: "use local
/// storage for now", same as `CustomerRepositoryImpl`). [resetToDefaults]/
/// [clearCache] only ever touch this module's own key — never another
/// feature's storage, even though several are reachable through the same
/// shared [SecureStorageService] primitive (see `SettingsLocalStorage`'s
/// header comment for why "Delete Local Data"/"Clear Cache" stay scoped
/// this way).
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SettingsLocalStorage localStorage})
      : _localStorage = localStorage;

  final SettingsLocalStorage _localStorage;

  @override
  Future<SettingsData> loadSettings() => _localStorage.read();

  @override
  Future<SettingsData> updateSettings(SettingsData data) async {
    await _localStorage.write(data);
    return data;
  }

  @override
  Future<SettingsData> resetToDefaults() async {
    const defaults = SettingsData();
    await _localStorage.write(defaults);
    return defaults;
  }

  @override
  Future<int> storageUsageBytes() async {
    final data = await _localStorage.read();
    return utf8.encode(jsonEncode(data.toJson())).length;
  }

  @override
  Future<void> clearCache() => _localStorage.clear();
}
