import '../models/merchant_application.dart';

/// Seam between the Riverpod controller and the actual data sources — lets
/// `MerchantOnboardingController` be unit-tested against a fake, without
/// touching real network/storage (see docs/07_CODING_RULES.md § 3).
abstract class MerchantOnboardingRepository {
  /// Reads any previously-cached application from local storage only — no
  /// network call. Used to resume the result/status screen after an app
  /// restart before a live refresh completes.
  Future<MerchantApplication?> restoreCachedApplication();

  /// Submits the merchant application (`POST /merchant/applications`) and
  /// caches the result locally.
  Future<MerchantApplication> submit({
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
  });

  /// Polls Surfboard live for the current status and refreshes the cache.
  Future<MerchantApplication> refreshStatus(String applicationId);
}
