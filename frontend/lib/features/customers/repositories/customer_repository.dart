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

  /// Real since Phase CRM-1 (see [CustomerRepositoryImpl.recordPurchase]) —
  /// every sale Billing records against this customer, newest first.
  Future<List<CustomerPurchase>> getPurchaseHistory(String customerId,
      {String? cursor, int limit = 20});

  /// Called once per completed sale (Phase CRM-1) — the one and only write
  /// path for a customer's lifetime stats/loyalty points/purchase history.
  /// `itemNames` is a flat product-name summary (see [CustomerPurchase]'s
  /// own header comment for why); `receiptNumber` defaults to a generated
  /// one if the caller doesn't have a real one to hand (e.g. a test
  /// payment). Never called from this module itself — the caller (Billing's
  /// payment-success hook) owns deciding *whether* a sale counts.
  Future<CustomerModel> recordPurchase(
    String customerId, {
    required double amount,
    required List<String> itemNames,
    required String paymentMethod,
    required DateTime purchasedAt,
    String? receiptNumber,
  });

  /// A customer's most-frequently-purchased product names, most-bought
  /// first — derived from [getPurchaseHistory], never a second source of
  /// truth. Empty until at least one purchase has been recorded for them.
  Future<List<({String name, int timesPurchased})>> getFavoriteProducts(
      String customerId,
      {int limit = 5});
}
