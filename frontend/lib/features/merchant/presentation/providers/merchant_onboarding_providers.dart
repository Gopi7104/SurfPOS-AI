import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/providers/auth_providers.dart';
import '../../data/datasources/merchant_onboarding_api_service.dart';
import '../../data/datasources/merchant_onboarding_local_storage.dart';
import '../../data/models/merchant_application.dart';
import '../../data/repositories/merchant_onboarding_repository.dart';
import '../../data/repositories/merchant_onboarding_repository_impl.dart';
import '../controllers/merchant_onboarding_controller.dart';

/// DI wiring for the merchant-onboarding feature — the only place these
/// concrete classes are constructed (see docs/07_CODING_RULES.md § 3),
/// mirroring `authentication/providers/auth_providers.dart` exactly.
/// [apiClientProvider]/[secureStorageServiceProvider] are the authentication
/// feature's own providers, reused here rather than redeclared — both are
/// feature-agnostic shared infrastructure (see those providers' doc
/// comments), and a second `Provider<ApiClient>` would construct a second
/// dio instance with no `authTokenProvider` wired to it.

final merchantOnboardingApiServiceProvider = Provider<MerchantOnboardingApiService>((ref) {
  return MerchantOnboardingApiService(ref.watch(apiClientProvider));
});

final merchantOnboardingLocalStorageProvider = Provider<MerchantOnboardingLocalStorage>((ref) {
  return MerchantOnboardingLocalStorage(ref.watch(secureStorageServiceProvider));
});

final merchantOnboardingRepositoryProvider = Provider<MerchantOnboardingRepository>((ref) {
  return MerchantOnboardingRepositoryImpl(
    apiService: ref.watch(merchantOnboardingApiServiceProvider),
    localStorage: ref.watch(merchantOnboardingLocalStorageProvider),
  );
});

final merchantOnboardingControllerProvider =
    AsyncNotifierProvider<MerchantOnboardingController, MerchantApplication?>(
  MerchantOnboardingController.new,
);
