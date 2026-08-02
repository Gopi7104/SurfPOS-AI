import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/models/inventory_query.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/providers/inventory_providers.dart';

/// Real low-stock products for the Dashboard's Low Stock section when no
/// demo dataset is active — reads the existing, already-public
/// `InventoryRepository` read-only (same `InventoryQuery(stockFilter:
/// lowStock)` shape Inventory's own list/filter bar already uses), never a
/// new write path. `autoDispose` so a stale list never survives navigating
/// away and back.
final dashboardLowStockProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, uid) async {
  final page = await ref.watch(inventoryRepositoryProvider).listProducts(
        const InventoryQuery(stockFilter: StockFilter.lowStock),
        limit: 10,
      );
  return page.items;
});
