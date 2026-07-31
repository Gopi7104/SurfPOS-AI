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

final merchantOnboardingApiServiceProvider =
    Provider<MerchantOnboardingApiService>((ref) {
  return MerchantOnboardingApiService(ref.watch(apiClientProvider));
});

/// Keyed by Firebase uid — the local cache key itself embeds the uid (see
/// [MerchantOnboardingLocalStorage]), so this must be a `.family` too:
/// a plain singleton here would hand every uid the same
/// [MerchantOnboardingLocalStorage] instance, but the uid is only known at
/// read time, which is exactly what `.family` provides.
final merchantOnboardingLocalStorageProvider =
    Provider.family<MerchantOnboardingLocalStorage, String>((ref, uid) {
  return MerchantOnboardingLocalStorage(
      ref.watch(secureStorageServiceProvider), uid);
});

/// Keyed by Firebase uid (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user
/// isolation fix) — without this, Merchant B's controller would resolve the
/// same repository instance as Merchant A's and could read Merchant A's
/// cached application straight out of local storage on `build()`.
final merchantOnboardingRepositoryProvider =
    Provider.family<MerchantOnboardingRepository, String>((ref, uid) {
  return MerchantOnboardingRepositoryImpl(
    apiService: ref.watch(merchantOnboardingApiServiceProvider),
    localStorage: ref.watch(merchantOnboardingLocalStorageProvider(uid)),
  );
});

/// Keyed by Firebase uid — never a global singleton (see
/// docs/22_DEVELOPMENT_ROADMAP.md, cross-user isolation fix). `autoDispose`
/// frees a previous user's cached application the moment nothing watches it
/// anymore (i.e. as soon as the signed-in uid changes).
final merchantOnboardingControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MerchantOnboardingController, MerchantApplication?, String>(
  MerchantOnboardingController.new,
);
