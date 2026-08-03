import '../../../core/network/api_client.dart';
import '../models/sales_record.dart';

/// The whole sales ledger, as one JSON array via the backend's
/// `/reports/sales` bulk-sync endpoint — same `readAll()`/`writeAll()` shape
/// a per-device local-storage class would have, so [SalesLedgerRepositoryImpl]
/// needs zero logic changes to work against Firebase-backed persistence
/// (see backend/src/modules/reports/salesLedger.repository.js).
class SalesLedgerApiStorage {
  SalesLedgerApiStorage(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SalesRecord>> readAll() async {
    final data = await _apiClient.get('/reports/sales', requiresAuth: true);
    final raw = data['records'] as List<dynamic>? ?? [];
    return raw
        .map((entry) => SalesRecord.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAll(List<SalesRecord> records) {
    return _apiClient.post(
      '/reports/sales',
      requiresAuth: true,
      body: {'records': records.map((r) => r.toJson()).toList()},
    );
  }
}
