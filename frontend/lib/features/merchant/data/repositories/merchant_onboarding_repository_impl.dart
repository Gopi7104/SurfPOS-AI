import '../datasources/merchant_onboarding_api_service.dart';
import '../datasources/merchant_onboarding_local_storage.dart';
import '../models/merchant_application.dart';
import 'merchant_onboarding_repository.dart';

/// Owns all cross-data-source orchestration for merchant onboarding — the
/// only place that knows a successful submit/refresh must also update the
/// local cache. `MerchantOnboardingController` talks only to the
/// [MerchantOnboardingRepository] interface.
class MerchantOnboardingRepositoryImpl implements MerchantOnboardingRepository {
  MerchantOnboardingRepositoryImpl({
    required MerchantOnboardingApiService apiService,
    required MerchantOnboardingLocalStorage localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  final MerchantOnboardingApiService _apiService;
  final MerchantOnboardingLocalStorage _localStorage;

  @override
  Future<MerchantApplication?> restoreCachedApplication() {
    return _localStorage.readCachedApplication();
  }

  @override
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
  }) async {
    final application = await _apiService.submit(
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
    );
    await _localStorage.cacheApplication(application);
    return application;
  }

  @override
  Future<MerchantApplication> refreshStatus(String applicationId) async {
    final application = await _apiService.getStatus(applicationId);
    await _localStorage.cacheApplication(application);
    return application;
  }
}
