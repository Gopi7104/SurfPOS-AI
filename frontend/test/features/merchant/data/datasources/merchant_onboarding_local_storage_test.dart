import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/merchant/data/datasources/merchant_onboarding_local_storage.dart';

import '../../fakes/fake_merchant_onboarding_repository.dart';

/// In-memory [SecureStorageService] double — no platform channel involved,
/// so these tests exercise the real key-scoping logic without touching
/// `flutter_secure_storage`.
class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

void main() {
  group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test('two different uids sharing the same underlying storage never see '
        "each other's cached application", () async {
      final storage = _FakeSecureStorageService();
      final applicationA = testMerchantApplication(applicationId: 'app-a');

      final storageForA = MerchantOnboardingLocalStorage(storage, 'uid-merchant-a');
      final storageForB = MerchantOnboardingLocalStorage(storage, 'uid-merchant-b');

      await storageForA.cacheApplication(applicationA);

      // Merchant B's own scoped storage instance must never read back
      // Merchant A's cached application, even though both instances share
      // the exact same underlying SecureStorageService/keychain.
      final resultB = await storageForB.readCachedApplication();
      expect(resultB, isNull);

      final resultA = await storageForA.readCachedApplication();
      expect(resultA?.applicationId, 'app-a');
    });

    test("clearing one uid's cache does not affect another uid's cache", () async {
      final storage = _FakeSecureStorageService();
      final applicationA = testMerchantApplication(applicationId: 'app-a');
      final applicationB = testMerchantApplication(applicationId: 'app-b');

      final storageForA = MerchantOnboardingLocalStorage(storage, 'uid-merchant-a');
      final storageForB = MerchantOnboardingLocalStorage(storage, 'uid-merchant-b');

      await storageForA.cacheApplication(applicationA);
      await storageForB.cacheApplication(applicationB);

      await storageForA.clear();

      expect(await storageForA.readCachedApplication(), isNull);
      expect((await storageForB.readCachedApplication())?.applicationId, 'app-b');
    });
  });
}
