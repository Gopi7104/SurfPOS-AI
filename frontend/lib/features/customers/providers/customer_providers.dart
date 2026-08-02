import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/customer_form_controller.dart';
import '../controllers/customer_list_controller.dart';
import '../models/customer_model.dart';
import '../models/customer_purchase.dart';
import '../models/customer_stats.dart';
import '../repositories/customer_local_storage.dart';
import '../repositories/customer_repository.dart';
import '../repositories/customer_repository_impl.dart';

/// DI wiring for the Customers feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3), reusing the
/// authentication feature's shared [secureStorageServiceProvider] rather
/// than redeclaring a second `SecureStorageService`.
///
/// Both are `.family`, not plain [Provider]s, because the local-storage
/// key itself embeds the uid (see [CustomerLocalStorage]) — a plain
/// singleton would hand every uid the same instance, but the uid is only
/// known at read time, exactly what `.family` provides (mirrors
/// `merchantOnboardingLocalStorageProvider`/
/// `merchantOnboardingRepositoryProvider`).
final customerLocalStorageProvider =
    Provider.family<CustomerLocalStorage, String>((ref, uid) {
  return CustomerLocalStorage(ref.watch(secureStorageServiceProvider), uid);
});

final customerRepositoryProvider =
    Provider.family<CustomerRepository, String>((ref, uid) {
  return CustomerRepositoryImpl(
      localStorage: ref.watch(customerLocalStorageProvider(uid)));
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

/// A single customer's Purchase History — always empty today, see
/// `CustomerRepositoryImpl`'s header comment.
final customerPurchaseHistoryProvider = FutureProvider.autoDispose
    .family<List<CustomerPurchase>, CustomerDetailsKey>((ref, key) {
  return ref
      .watch(customerRepositoryProvider(key.uid))
      .getPurchaseHistory(key.customerId);
});
