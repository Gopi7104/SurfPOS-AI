import 'package:surfpos_ai/features/merchant/data/models/merchant_application.dart';
import 'package:surfpos_ai/features/merchant/data/repositories/merchant_onboarding_repository.dart';

/// Configurable [MerchantOnboardingRepository] test double — mirrors
/// `test/features/authentication/fakes/fake_auth_repository.dart`'s shape:
/// every method defaults to a no-op/empty behavior, overridable per test via
/// the constructor, never touching real network/storage.
class FakeMerchantOnboardingRepository implements MerchantOnboardingRepository {
  FakeMerchantOnboardingRepository({
    Future<MerchantApplication?> Function()? restoreCachedApplication,
    Future<MerchantApplication> Function({
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
    })? submit,
    Future<MerchantApplication> Function(String applicationId)? refreshStatus,
  })  : _restoreCachedApplication =
            restoreCachedApplication ?? (() async => null),
        _submit = submit,
        _refreshStatus = refreshStatus;

  final Future<MerchantApplication?> Function() _restoreCachedApplication;
  final Future<MerchantApplication> Function({
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
  })? _submit;
  final Future<MerchantApplication> Function(String applicationId)?
      _refreshStatus;

  @override
  Future<MerchantApplication?> restoreCachedApplication() =>
      _restoreCachedApplication();

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
  }) {
    final submit = _submit;
    if (submit == null) throw UnimplementedError();
    return submit(
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
  }

  @override
  Future<MerchantApplication> refreshStatus(String applicationId) {
    final refreshStatus = _refreshStatus;
    if (refreshStatus == null) throw UnimplementedError();
    return refreshStatus(applicationId);
  }
}

MerchantApplication testMerchantApplication({
  String applicationId = 'app-1',
  String? merchantId,
  String? storeId,
  ApplicationStatus applicationStatus = ApplicationStatus.applicationInitiated,
  String? applicationUrl = 'https://surfkyb.com/app-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return MerchantApplication(
    applicationId: applicationId,
    merchantId: merchantId,
    storeId: storeId,
    applicationStatus: applicationStatus,
    applicationUrl: applicationUrl,
    shortLinkUrl: null,
    submittedAt: now,
    updatedAt: now,
  );
}
