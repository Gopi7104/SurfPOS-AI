import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/providers/inventory_providers.dart';
import '../controllers/billing_controller.dart';
import '../models/billing_state.dart';
import '../repositories/billing_repository.dart';
import '../repositories/billing_repository_impl.dart';

/// DI wiring for the Billing feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3). Depends on
/// Inventory's own [inventoryRepositoryProvider] rather than constructing a
/// second `ApiClient`/repository — Billing requests products *through* the
/// Inventory layer, per docs/22_DEVELOPMENT_ROADMAP.md (Phase 3).
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(
      inventoryRepository: ref.watch(inventoryRepositoryProvider));
});

/// Keyed by Firebase uid (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user
/// isolation fix) — never a global singleton. A different signed-in account
/// gets a completely separate cart instance; `autoDispose` clears a
/// previous user's in-progress sale the moment nothing watches it anymore.
final billingControllerProvider = NotifierProvider.autoDispose
    .family<BillingController, BillingState, String>(
  BillingController.new,
);
