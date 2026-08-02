import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../models/settings_data.dart';

/// The whole [SettingsData] blob, as one JSON value under one key in
/// [SecureStorageService] — same read-modify-write-the-whole-thing shape
/// `CustomerLocalStorage`/`ProductImageLocalStorage` already use. Scoped
/// to a single Firebase [uid] (the key embeds it) — same cross-user
/// isolation rule every other local cache in this app follows.
class SettingsLocalStorage {
  SettingsLocalStorage(this._storage, this.uid);

  final SecureStorageService _storage;
  final String uid;

  String get _key => 'settings.data.$uid';

  Future<SettingsData> read() async {
    final raw = await _storage.read(_key);
    if (raw == null) return const SettingsData();
    return SettingsData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(SettingsData data) {
    return _storage.write(_key, jsonEncode(data.toJson()));
  }

  Future<void> clear() => _storage.delete(_key);
}
