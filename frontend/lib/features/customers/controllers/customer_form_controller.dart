import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_draft.dart';
import '../models/customer_model.dart';
import '../providers/customer_providers.dart';

/// Add/Edit Customer form submission state for exactly one Firebase uid
/// (see [customerFormControllerProvider] — a `.family` provider) — mirrors
/// `InventoryFormController` exactly. `null` until [create]/[updateCustomer]
/// succeeds; the form pages navigate away on success rather than rendering
/// this state directly.
class CustomerFormController
    extends AutoDisposeFamilyAsyncNotifier<CustomerModel?, String> {
  @override
  Future<CustomerModel?> build(String uid) async => null;

  /// A no-op while a previous call is still in flight — the Save button is
  /// disabled by `state.isLoading` anyway, but guarding here too means a
  /// double-tap that lands before the rebuild can't race a second call
  /// through.
  Future<void> create(CustomerDraft draft) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider(arg)).createCustomer(draft),
    );
  }

  /// Named `updateCustomer`, not `update` — `AsyncNotifierBase` already
  /// declares an `update()` method, and shadowing it with an incompatible
  /// signature is a compile error (same reason
  /// `InventoryFormController.updateProduct` isn't called `update`).
  Future<void> updateCustomer(String customerId, CustomerDraft draft) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(customerRepositoryProvider(arg))
          .updateCustomer(customerId, draft),
    );
  }
}
