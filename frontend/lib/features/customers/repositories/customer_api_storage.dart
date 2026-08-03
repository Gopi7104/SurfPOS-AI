import '../../../core/network/api_client.dart';
import '../models/customer_model.dart';

/// The whole customer list, as one JSON array via the backend's `/customers`
/// bulk-sync endpoint — same `readAll()`/`writeAll()` shape a per-device
/// local-storage class would have, so [CustomerRepositoryImpl] needs zero
/// logic changes to work against Firebase-backed persistence (see
/// backend/src/modules/customers/customerData.repository.js).
class CustomerApiStorage {
  CustomerApiStorage(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CustomerModel>> readAll() async {
    final data = await _apiClient.get('/customers', requiresAuth: true);
    final raw = data['customers'] as List<dynamic>? ?? [];
    return raw
        .map((entry) => CustomerModel.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<CustomerModel> customers) {
    return _apiClient.post(
      '/customers',
      requiresAuth: true,
      body: {'customers': customers.map((c) => c.toJson()).toList()},
    );
  }
}
