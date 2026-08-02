import 'package:flutter/material.dart' show ThemeMode;

import '../../../core/storage/secure_storage_service.dart';
import 'theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._storage);

  final SecureStorageService _storage;

  static const _key = 'settings.themeMode';

  @override
  Future<ThemeMode> loadThemeMode() async {
    final raw = await _storage.read(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) {
    return _storage.write(_key, mode.name);
  }
}
