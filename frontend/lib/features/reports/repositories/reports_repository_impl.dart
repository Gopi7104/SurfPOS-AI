import 'package:flutter/material.dart' show DateTimeRange;

import '../../inventory/models/inventory_query.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../models/inventory_overview.dart';
import '../models/order_summary.dart';
import '../models/report_period.dart';
import '../models/reports_snapshot.dart';
import '../models/sales_summary.dart';
import 'reports_repository.dart';

/// Builds [ReportsSnapshot]s entirely from data already on this device/this
/// account — no `/reports` backend endpoint exists yet (Phase 5.1 scope).
///
/// [InventoryOverview] is real, live data: it reads `InventoryRepository`
/// directly, the same bounded-sample approach `inventoryStatsProvider`
/// already uses (stock levels exist independently of any sale ever having
/// happened). Every other section — Sales Summary, Orders, Top Selling
/// Products, the Sales Chart, Category Breakdown, Recent Transactions —
/// has no real data source to read *yet*: this app has no persisted
/// Sale/order history at all. `ReceiptModel` is built client-side and
/// discarded once shown (see `ReceiptModel`'s own header comment), and
/// `webhook.controller.js` explicitly documents that there is no
/// Sale/order persistence layer yet either. So those sections come back
/// empty/zero — genuinely empty, not a bug — until a persistence layer for
/// completed sales exists (out of scope here; Reports must not modify
/// Payment/Receipt/Billing to add one). [period]/[customRange] are still
/// threaded all the way through so wiring a real data source later is a
/// pure repository-side change with no controller/UI change needed, the
/// same forward-compatible shape `BusinessSummary` used for the Dashboard.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required InventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository;

  final InventoryRepository _inventoryRepository;

  /// Matches `inventoryStatsProvider`'s own documented small-catalog
  /// assumption (docs/08_ARCHITECTURE_DECISIONS.md § ADR-024).
  static const _statsSampleLimit = 100;

  @override
  Future<ReportsSnapshot> loadReports({
    required ReportPeriod period,
    DateTimeRange? customRange,
  }) async {
    final inventoryOverview = await _loadInventoryOverview();

    return ReportsSnapshot(
      salesSummary: SalesSummary.empty(),
      orderSummary: OrderSummary.empty(),
      inventoryOverview: inventoryOverview,
      topProducts: const [],
      salesTrend: const [],
      categoryBreakdown: const [],
      recentTransactions: const [],
      generatedAt: DateTime.now(),
    );
  }

  Future<InventoryOverview> _loadInventoryOverview() async {
    final page = await _inventoryRepository.listProducts(
      const InventoryQuery(),
      limit: _statsSampleLimit,
    );
    final categories = await _inventoryRepository.listCategories();

    return InventoryOverview(
      productsCount: page.items.length,
      lowStockCount: page.items.where((product) => product.isLowStock).length,
      outOfStockCount:
          page.items.where((product) => product.isOutOfStock).length,
      categoriesCount: categories.length,
      isApproximate: page.hasMore,
    );
  }
}
