import '../../../core/network/api_client.dart';
import '../models/customer_purchase.dart';

/// The whole purchase-history list (across every customer), as one JSON
/// array via the backend's `/customers/purchases` bulk-sync endpoint — same
/// `readAll()`/`writeAll()` shape a per-device local-storage class would
/// have, so [CustomerRepositoryImpl] needs zero logic changes to work
/// against Firebase-backed persistence.
class CustomerPurchaseApiStorage {
  CustomerPurchaseApiStorage(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CustomerPurchase>> readAll() async {
    final data =
        await _apiClient.get('/customers/purchases', requiresAuth: true);
    final raw = data['purchases'] as List<dynamic>? ?? [];
    return raw
        .map(
            (entry) => CustomerPurchase.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<CustomerPurchase> purchases) {
    return _apiClient.post(
      '/customers/purchases',
      requiresAuth: true,
      body: {'purchases': purchases.map((p) => p.toJson()).toList()},
    );
  }
}
