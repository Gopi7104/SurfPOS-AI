import 'dart:convert';

import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_user.dart';

/// Caches a snapshot of the signed-in user's profile plus a login flag — not
/// the Firebase ID token itself (see `core/network/api_client.dart`'s doc
/// comment for why). This exists purely so the Splash screen can make an
/// instant routing decision (Login vs Dashboard) before Firebase's own
/// session restore has finished; [AuthRepositoryImpl.restoreSession] still
/// re-verifies against `GET /auth/me` before trusting it.
class AuthLocalStorage {
  AuthLocalStorage(this._storage);

  final SecureStorageService _storage;

  static const _userKey = 'auth.cachedUser';
  static const _loggedInKey = 'auth.isLoggedIn';

  Future<void> cacheUser(AuthUser user) {
    return _storage.write(_userKey, jsonEncode(user.toJson()));
  }

  Future<AuthUser?> readCachedUser() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setLoggedIn(bool value) {
    return _storage.write(_loggedInKey, value.toString());
  }

  Future<bool> isLoggedIn() async {
    final raw = await _storage.read(_loggedInKey);
    return raw == 'true';
  }

  // Only this class's own keys — NOT deleteAll(). The same FlutterSecureStorage
  // keychain also holds customers/reports/inventory/settings/demo-data caches (each under
  // their own key prefix); deleteAll() here was wiping every one of those on every logout.
  Future<void> clear() => Future.wait([
        _storage.delete(_userKey),
        _storage.delete(_loggedInKey),
      ]);
}
