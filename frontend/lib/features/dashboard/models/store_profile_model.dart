/// Mirrors the `store` object returned by `GET /stores/:storeId` (see
/// `backend/src/integrations/surfboard/mappers/store.mapper.js#toDomain`) — a
/// live Surfboard read, never persisted in Firebase.
class StoreProfileModel {
  const StoreProfileModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.status,
  });

  final String? id;
  final String? merchantId;
  final String? name;
  final String? status;

  factory StoreProfileModel.fromJson(Map<String, dynamic> json) {
    return StoreProfileModel(
      id: json['id'] as String?,
      merchantId: json['merchantId'] as String?,
      name: json['name'] as String?,
      status: json['status'] as String?,
    );
  }
}
