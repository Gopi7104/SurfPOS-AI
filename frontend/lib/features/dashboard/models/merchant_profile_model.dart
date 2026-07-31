/// Mirrors the `merchant` object returned by `GET /merchant` (see
/// `backend/src/integrations/surfboard/mappers/merchant.mapper.js#toMerchantProfile`)
/// — a live Fetch Merchant Details read, never persisted in Firebase.
class MerchantProfileModel {
  const MerchantProfileModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.email,
    required this.phoneNumber,
    required this.mccCode,
    required this.countryCode,
  });

  final String? id;
  final String? name;
  final String? companyId;
  final String? email;
  final String? phoneNumber;
  final String? mccCode;
  final String? countryCode;

  factory MerchantProfileModel.fromJson(Map<String, dynamic> json) {
    return MerchantProfileModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      companyId: json['companyId'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      mccCode: json['mccCode'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }
}
