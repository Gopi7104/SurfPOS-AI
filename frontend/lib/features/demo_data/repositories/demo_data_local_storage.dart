import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../models/demo_business_snapshot.dart';

/// The whole [DemoBusinessSnapshot] blob, as one JSON value under its own
/// key in [SecureStorageService] — same shape `SettingsLocalStorage`/
/// `CustomerLocalStorage` already use, but under a completely separate key
/// so it can never collide with or overwrite any real merchant data.
/// Scoped to a single Firebase [uid], same cross-user isolation rule every
/// other local cache in this app follows.
class DemoDataLocalStorage {
  DemoDataLocalStorage(this._storage, this.uid);

  final SecureStorageService _storage;
  final String uid;

  String get _key => 'demo_data.snapshot.$uid';

  Future<DemoBusinessSnapshot?> read() async {
    final raw = await _storage.read(_key);
    if (raw == null) return null;
    return DemoBusinessSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(DemoBusinessSnapshot snapshot) {
    return _storage.write(_key, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() => _storage.delete(_key);
}
