import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/merchant_application.dart';
import '../providers/merchant_onboarding_providers.dart';

/// Onboarding-application state for the whole app: `null` = nothing
/// submitted yet, non-null = an application exists (any status). `build()`
/// restores the last locally-cached snapshot (no network call) so the
/// wizard's result screen survives an app restart; callers should still
/// `refreshStatus()` to get the live value.
class MerchantOnboardingController extends AsyncNotifier<MerchantApplication?> {
  @override
  Future<MerchantApplication?> build() {
    return ref.read(merchantOnboardingRepositoryProvider).restoreCachedApplication();
  }

  /// Submits the merchant application. A no-op while a previous call is
  /// still in flight — this is the duplicate-submission guard: the wizard's
  /// submit button is disabled by [state.isLoading] anyway, but guarding
  /// here too means a double-tap that lands before the rebuild can't race a
  /// second network call through.
  Future<void> submit({
    required String country,
    required String corporateId,
    String? legalName,
    String? mccCode,
    required String organisationAddressLine1,
    String? organisationAddressLine2,
    String? organisationCareOf,
    required String organisationCity,
    required String organisationCountryCode,
    required String organisationPostalCode,
    String? organisationPhoneCode,
    String? organisationPhoneNumber,
    String? organisationEmail,
    required String storeName,
    required String storeEmail,
    required String storePhoneCode,
    required String storePhoneNumber,
    required String storeAddressLine1,
    String? storeAddressLine2,
    String? storeCareOf,
    required String storeCity,
    required String storeCountryCode,
    required String storePostalCode,
  }) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(merchantOnboardingRepositoryProvider).submit(
            country: country,
            corporateId: corporateId,
            legalName: legalName,
            mccCode: mccCode,
            organisationAddressLine1: organisationAddressLine1,
            organisationAddressLine2: organisationAddressLine2,
            organisationCareOf: organisationCareOf,
            organisationCity: organisationCity,
            organisationCountryCode: organisationCountryCode,
            organisationPostalCode: organisationPostalCode,
            organisationPhoneCode: organisationPhoneCode,
            organisationPhoneNumber: organisationPhoneNumber,
            organisationEmail: organisationEmail,
            storeName: storeName,
            storeEmail: storeEmail,
            storePhoneCode: storePhoneCode,
            storePhoneNumber: storePhoneNumber,
            storeAddressLine1: storeAddressLine1,
            storeAddressLine2: storeAddressLine2,
            storeCareOf: storeCareOf,
            storeCity: storeCity,
            storeCountryCode: storeCountryCode,
            storePostalCode: storePostalCode,
          ),
    );
  }

  /// Polls Surfboard live for the current application's status. A no-op if
  /// there's nothing to refresh yet, or a refresh is already in flight.
  Future<void> refreshStatus() async {
    final current = state.valueOrNull;
    if (current == null || state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(merchantOnboardingRepositoryProvider).refreshStatus(current.applicationId),
    );
  }
}
