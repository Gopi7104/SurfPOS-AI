import '../../../../core/network/api_client.dart';
import '../models/merchant_application.dart';

/// Thin wrapper around [ApiClient] for the `/merchant/applications` routes —
/// no business logic, no Surfboard calls (those are the backend's job), just
/// request shaping and response parsing (see
/// `backend/src/routes/merchantApplication.routes.js`). Request shape
/// mirrors the confirmed Surfboard Create Merchant API exactly (see
/// docs/08_ARCHITECTURE_DECISIONS.md § ADR-026) — never the flat
/// businessName/businessType shape from earlier, unconfirmed backend code.
class MerchantOnboardingApiService {
  MerchantOnboardingApiService(this._client);

  final ApiClient _client;

  /// `POST /merchant/applications` — submits the merchant application.
  /// [organisationPhoneCode]/[organisationPhoneNumber] are optional together
  /// (Surfboard only requires organisation contact details for PF
  /// partners); Store contact/address are always required — SurfPOS is
  /// in-store-only, so a merchant with no store can't accept payments yet.
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
    final data = await _client.post(
      '/merchant/applications',
      requiresAuth: true,
      body: {
        'country': country,
        'organisation': {
          'corporateId': corporateId,
          if (legalName != null && legalName.isNotEmpty) 'legalName': legalName,
          if (mccCode != null && mccCode.isNotEmpty) 'mccCode': mccCode,
          'address': {
            if (organisationCareOf != null && organisationCareOf.isNotEmpty)
              'careOf': organisationCareOf,
            'addressLine1': organisationAddressLine1,
            if (organisationAddressLine2 != null &&
                organisationAddressLine2.isNotEmpty)
              'addressLine2': organisationAddressLine2,
            'city': organisationCity,
            'countryCode': organisationCountryCode,
            'postalCode': organisationPostalCode,
          },
          if (organisationPhoneCode != null && organisationPhoneNumber != null)
            'phoneNumber': {
              'code': organisationPhoneCode,
              'number': organisationPhoneNumber
            },
          if (organisationEmail != null && organisationEmail.isNotEmpty)
            'email': organisationEmail,
        },
        'store': {
          'name': storeName,
          'email': storeEmail,
          'phoneNumber': {'code': storePhoneCode, 'number': storePhoneNumber},
          'address': {
            if (storeCareOf != null && storeCareOf.isNotEmpty)
              'careOf': storeCareOf,
            'addressLine1': storeAddressLine1,
            if (storeAddressLine2 != null && storeAddressLine2.isNotEmpty)
              'addressLine2': storeAddressLine2,
            'city': storeCity,
            'countryCode': storeCountryCode,
            'postalCode': storePostalCode,
          },
        },
      },
    );
    return MerchantApplication.fromJson(
        data['application'] as Map<String, dynamic>);
  }

  /// `GET /merchant/applications/:id` — the last cached snapshot.
  Future<MerchantApplication> getById(String applicationId) async {
    final data = await _client.get('/merchant/applications/$applicationId',
        requiresAuth: true);
    return MerchantApplication.fromJson(
        data['application'] as Map<String, dynamic>);
  }

  /// `GET /merchant/applications/:id/status` — polls Surfboard live and
  /// returns the refreshed record.
  Future<MerchantApplication> getStatus(String applicationId) async {
    final data = await _client.get(
        '/merchant/applications/$applicationId/status',
        requiresAuth: true);
    return MerchantApplication.fromJson(
        data['application'] as Map<String, dynamic>);
  }

  /// `GET /merchant/applications` — the caller's own application(s), 0 or 1.
  Future<List<MerchantApplication>> list() async {
    final data =
        await _client.get('/merchant/applications', requiresAuth: true);
    return (data['applications'] as List<dynamic>)
        .map((json) =>
            MerchantApplication.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
