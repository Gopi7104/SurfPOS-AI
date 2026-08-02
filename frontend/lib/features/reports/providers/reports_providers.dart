import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/providers/inventory_providers.dart';
import '../controllers/reports_controller.dart';
import '../models/reports_state.dart';
import '../repositories/reports_repository.dart';
import '../repositories/reports_repository_impl.dart';
import 'sales_ledger_providers.dart';

/// DI wiring for the Reports feature — reuses Inventory's own
/// [inventoryRepositoryProvider] rather than constructing a second
/// `InventoryRepository`, matching the established cross-feature-provider-
/// reuse convention (see `dashboard_providers.dart`,
/// `billing_providers.dart`). `.family`-by-uid since Phase CRM-2's real
/// sales ledger is itself uid-scoped local storage (see
/// `salesLedgerRepositoryProvider`) — Inventory's own repository stays a
/// single shared instance either way (it's backend-API-scoped via the
/// signed-in user's auth token, not a local per-uid file).
final reportsRepositoryProvider =
    Provider.family<ReportsRepository, String>((ref, uid) {
  return ReportsRepositoryImpl(
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    salesLedgerRepository: ref.watch(salesLedgerRepositoryProvider(uid)),
  );
});

/// Keyed by Firebase uid — never a global singleton, same cross-user
/// isolation pattern every controller in this app follows (see
/// `dashboardControllerProvider`).
final reportsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReportsController, ReportsState, String>(
  ReportsController.new,
);
