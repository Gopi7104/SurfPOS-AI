import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin, generic wrapper around [FlutterSecureStorage] — the only place
/// this package is imported directly, so every feature needing secure
/// storage goes through one implementation (see docs/07_CODING_RULES.md § 8).
///
/// Deliberately narrow: read/write/delete a string by key, nothing more.
/// Feature-specific meaning (which keys, what they hold) belongs in that
/// feature's own storage class — see
/// `features/authentication/data/datasources/auth_local_storage.dart`.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
