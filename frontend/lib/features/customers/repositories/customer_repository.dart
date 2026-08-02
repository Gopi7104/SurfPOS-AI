import '../models/customer_draft.dart';
import '../models/customer_model.dart';
import '../models/customer_page.dart';
import '../models/customer_purchase.dart';
import '../models/customer_query.dart';
import '../models/customer_stats.dart';

/// Seam between the Riverpod controllers and wherever customer data
/// actually lives — mirrors `InventoryRepository`. Local-storage-only for
/// now (see [CustomerRepositoryImpl]'s header comment); every method's
/// shape (cursor pagination, draft-in/model-out, id-addressed reads) is
/// the same shape a future `/customers` backend would use, so a
/// backend-backed implementation can replace this one later without any
/// controller or widget changing.
abstract class CustomerRepository {
  Future<CustomerPage> listCustomers(CustomerQuery query,
      {String? cursor, int limit = 20});

  Future<CustomerModel> getCustomer(String customerId);

  Future<CustomerModel> createCustomer(CustomerDraft draft);

  Future<CustomerModel> updateCustomer(String customerId, CustomerDraft draft);

  /// Soft delete — the record is flagged, never physically removed (see
  /// [CustomerModel.isDeleted]).
  Future<void> deleteCustomer(String customerId);

  Future<CustomerModel> addNote(String customerId, String text);

  Future<CustomerStats> getStats();

  /// Always empty today — see [CustomerRepositoryImpl]'s header comment
  /// for why. [cursor]/[limit] are still accepted so [PurchaseHistoryPage]
  /// never needs to change once a real source exists.
  Future<List<CustomerPurchase>> getPurchaseHistory(String customerId,
      {String? cursor, int limit = 20});
}
