import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/customer_form_controller.dart';
import '../controllers/customer_list_controller.dart';
import '../models/customer_model.dart';
import '../models/customer_purchase.dart';
import '../models/customer_stats.dart';
import '../repositories/customer_api_storage.dart';
import '../repositories/customer_purchase_api_storage.dart';
import '../repositories/customer_repository.dart';
import '../repositories/customer_repository_impl.dart';

/// DI wiring for the Customers feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3), reusing the
/// authentication feature's shared [apiClientProvider]. Customer/purchase
/// data is persisted server-side in Firebase (see
/// backend/src/modules/customers/customerData.repository.js) — scoped to
/// the caller's merchant via their auth token, not a per-device local key —
/// so it survives logout/reinstall/a new device instead of living only on
/// one device's secure storage.
final customerApiStorageProvider = Provider<CustomerApiStorage>((ref) {
  return CustomerApiStorage(ref.watch(apiClientProvider));
});

final customerPurchaseApiStorageProvider =
    Provider<CustomerPurchaseApiStorage>((ref) {
  return CustomerPurchaseApiStorage(ref.watch(apiClientProvider));
});

final customerRepositoryProvider =
    Provider.family<CustomerRepository, String>((ref, uid) {
  return CustomerRepositoryImpl(
    localStorage: ref.watch(customerApiStorageProvider),
    purchaseLocalStorage: ref.watch(customerPurchaseApiStorageProvider),
  );
});

/// Keyed by Firebase uid — never a global singleton (cross-user isolation,
/// see docs/22_DEVELOPMENT_ROADMAP.md). `autoDispose` frees a previous
/// user's loaded customers the moment nothing watches it anymore.
final customerListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerListController, CustomerListState, String>(
  CustomerListController.new,
);

final customerFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerFormController, CustomerModel?, String>(
  CustomerFormController.new,
);

/// One customer's live details — keyed by (uid, customerId), same pattern
/// as `productDetailsProvider`. `autoDispose` so a stale customer never
/// survives navigating away and back.
typedef CustomerDetailsKey = ({String uid, String customerId});

final customerDetailsProvider = FutureProvider.autoDispose
    .family<CustomerModel, CustomerDetailsKey>((ref, key) {
  return ref
      .watch(customerRepositoryProvider(key.uid))
      .getCustomer(key.customerId);
});

/// Customer Statistics section's 6 cards.
final customerStatsProvider =
    FutureProvider.autoDispose.family<CustomerStats, String>((ref, uid) {
  return ref.watch(customerRepositoryProvider(uid)).getStats();
});

/// A single customer's Purchase History — real since Phase CRM-1, backed by
/// whatever Billing has recorded via `CustomerRepository.recordPurchase`.
final customerPurchaseHistoryProvider = FutureProvider.autoDispose
    .family<List<CustomerPurchase>, CustomerDetailsKey>((ref, key) {
  return ref
      .watch(customerRepositoryProvider(key.uid))
      .getPurchaseHistory(key.customerId);
});

/// A single customer's most-purchased products — Phase CRM-1, derived from
/// [customerPurchaseHistoryProvider]'s same underlying data.
final customerFavoriteProductsProvider = FutureProvider.autoDispose
    .family<List<({String name, int timesPurchased})>, CustomerDetailsKey>(
        (ref, key) {
  return ref
      .watch(customerRepositoryProvider(key.uid))
      .getFavoriteProducts(key.customerId);
});
