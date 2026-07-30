import 'dart:convert';

import '../../../../core/storage/secure_storage_service.dart';
import '../models/merchant_application.dart';

/// Caches the last-known onboarding application locally so the wizard's
/// result/status screen survives an app restart without an extra network
/// round-trip — mirrors `AuthLocalStorage`'s snapshot-caching approach.
/// Unlike [AuthLocalStorage.clear], [clear] here only deletes this
/// feature's own keys, never [SecureStorageService.deleteAll] — merchant
/// onboarding state must not be wiped as a side effect of logging out (a
/// user can log back in and resume checking their application status).
class MerchantOnboardingLocalStorage {
  MerchantOnboardingLocalStorage(this._storage);

  final SecureStorageService _storage;

  static const _applicationKey = 'merchant.onboardingApplication';

  Future<void> cacheApplication(MerchantApplication application) {
    return _storage.write(_applicationKey, jsonEncode(application.toJson()));
  }

  Future<MerchantApplication?> readCachedApplication() async {
    final raw = await _storage.read(_applicationKey);
    if (raw == null) return null;
    return MerchantApplication.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() => _storage.delete(_applicationKey);
}
