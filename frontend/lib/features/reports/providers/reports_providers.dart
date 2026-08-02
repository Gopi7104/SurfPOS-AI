import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/providers/inventory_providers.dart';
import '../controllers/reports_controller.dart';
import '../models/reports_state.dart';
import '../repositories/reports_repository.dart';
import '../repositories/reports_repository_impl.dart';

/// DI wiring for the Reports feature — reuses Inventory's own
/// [inventoryRepositoryProvider] rather than constructing a second
/// `InventoryRepository`, matching the established cross-feature-provider-
/// reuse convention (see `dashboard_providers.dart`,
/// `billing_providers.dart`).
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
      inventoryRepository: ref.watch(inventoryRepositoryProvider));
});

/// Keyed by Firebase uid — never a global singleton, same cross-user
/// isolation pattern every controller in this app follows (see
/// `dashboardControllerProvider`).
final reportsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReportsController, ReportsState, String>(
  ReportsController.new,
);
