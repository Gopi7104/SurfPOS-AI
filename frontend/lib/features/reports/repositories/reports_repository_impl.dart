import 'package:flutter/material.dart' show DateTimeRange;

import '../../inventory/models/inventory_query.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../models/category_breakdown_slice.dart';
import '../models/inventory_overview.dart';
import '../models/order_summary.dart';
import '../models/payment_breakdown_slice.dart';
import '../models/recent_transaction.dart';
import '../models/report_period.dart';
import '../models/reports_snapshot.dart';
import '../models/sales_ledger_snapshot.dart';
import '../models/sales_record.dart';
import '../models/sales_summary.dart';
import '../models/sales_trend_point.dart';
import '../models/top_product.dart';
import 'reports_repository.dart';
import 'sales_ledger_repository.dart';

/// Builds [ReportsSnapshot]s from data already on this device/this
/// account — no `/reports` backend endpoint exists yet (Phase 5.1 scope).
///
/// [InventoryOverview] is real, live data: it reads `InventoryRepository`
/// directly (stock levels exist independently of any sale ever having
/// happened). Every sales-shaped section (Sales/Order Summary, Top
/// Products, Sales Trend, Category/Payment Breakdown, Recent
/// Transactions) is now real too (Phase CRM-2) — computed from
/// [SalesLedgerRepository]'s recorded sales, the same real data
/// `Payments`' success hook writes on every completed sale. A merchant
/// who hasn't completed a real sale yet simply sees every section at
/// zero/empty — genuinely empty, not a bug — until Reports/Dashboard's own
/// demo-data fallback (see `ReportsHomePage`'s header comment) fills the
/// UI in for exploration instead.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({
    required InventoryRepository inventoryRepository,
    required SalesLedgerRepository salesLedgerRepository,
  })  : _inventoryRepository = inventoryRepository,
        _salesLedgerRepository = salesLedgerRepository;

  final InventoryRepository _inventoryRepository;
  final SalesLedgerRepository _salesLedgerRepository;

  /// Matches `inventoryStatsProvider`'s own documented small-catalog
  /// assumption (docs/08_ARCHITECTURE_DECISIONS.md § ADR-024).
  static const _statsSampleLimit = 100;

  @override
  Future<ReportsSnapshot> loadReports({
    required ReportPeriod period,
    DateTimeRange? customRange,
  }) async {
    final inventoryOverview = await _loadInventoryOverview();
    final records = await _salesLedgerRepository.getAll();
    final ledger = SalesLedgerSnapshot(records);
    final range = ledger.rangeFor(
      period,
      customRangeStart: customRange?.start,
      customRangeEnd: customRange?.end,
    );
    final scoped = ledger.recordsFor(range.start, range.end);

    return ReportsSnapshot(
      salesSummary: SalesSummary(
        todaySales: ledger.todaySales,
        todaySalesGrowth: ledger.todaySalesGrowth,
        thisWeekSales: ledger.thisWeekSales,
        thisWeekGrowth: ledger.thisWeekGrowth,
        thisMonthSales: ledger.thisMonthSales,
        thisMonthGrowth: ledger.thisMonthGrowth,
        totalRevenue: ledger.totalRevenue,
      ),
      orderSummary: OrderSummary(
        todayOrders: ledger.todayOrders,
        completedOrders: scoped.length,
        cancelledOrders: 0,
        averageOrderValue: ledger.todayAverageOrderValue,
      ),
      inventoryOverview: inventoryOverview,
      topProducts: _topProducts(ledger, scoped),
      salesTrend: [
        for (final point in ledger.trendFor(range.start, range.end))
          SalesTrendPoint(label: point.label, amount: point.amount),
      ],
      categoryBreakdown: _categoryBreakdown(scoped, ledger),
      recentTransactions: [
        for (final record in ledger.mostRecent.take(20))
          RecentTransaction(
            receiptNumber: record.receiptNumber,
            customerName: record.customerName,
            amount: record.total,
            status: TransactionStatus.successful,
            paymentMethod: record.paymentMethod,
            time: record.occurredAt,
          ),
      ],
      paymentBreakdown: [
        for (final slice in ledger.paymentBreakdownFor(scoped))
          PaymentBreakdownSlice(
            method: slice.method,
            amount: slice.amount,
            percentage: slice.percentage,
          ),
      ],
      generatedAt: DateTime.now(),
    );
  }

  List<TopProduct> _topProducts(
      SalesLedgerSnapshot ledger, List<SalesRecord> scoped) {
    final rows = ledger.topProductsFor(scoped);
    final maxUnits = rows.isEmpty ? 0 : rows.first.unitsSold;
    return [
      for (final row in rows)
        TopProduct(
          productId: row.productId,
          name: row.name,
          sku: '',
          category: row.category,
          unitsSold: row.unitsSold,
          revenue: row.revenue,
          progress: maxUnits == 0 ? 0.0 : row.unitsSold / maxUnits,
        ),
    ];
  }

  List<CategoryBreakdownSlice> _categoryBreakdown(
      List<SalesRecord> scoped, SalesLedgerSnapshot ledger) {
    final totalScoped = scoped.fold(0.0, (sum, r) => sum + r.total);
    return [
      for (final slice in ledger.categoryBreakdownFor(scoped))
        CategoryBreakdownSlice(
          category: slice.category,
          revenue: slice.revenue,
          percentage:
              totalScoped == 0 ? 0 : (slice.revenue / totalScoped) * 100,
        ),
    ];
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
