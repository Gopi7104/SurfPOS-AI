import 'category_breakdown_slice.dart';
import 'inventory_overview.dart';
import 'order_summary.dart';
import 'recent_transaction.dart';
import 'sales_summary.dart';
import 'sales_trend_point.dart';
import 'top_product.dart';

/// Everything [ReportsHomePage] renders, for one [ReportPeriod] — the value
/// [ReportsRepository.loadReports] produces. See [ReportsRepositoryImpl]'s
/// header comment for which sections are real data today vs. empty
/// placeholders awaiting a sales-history persistence layer.
class ReportsSnapshot {
  const ReportsSnapshot({
    required this.salesSummary,
    required this.orderSummary,
    required this.inventoryOverview,
    required this.topProducts,
    required this.salesTrend,
    required this.categoryBreakdown,
    required this.recentTransactions,
    required this.generatedAt,
  });

  final SalesSummary salesSummary;
  final OrderSummary orderSummary;
  final InventoryOverview inventoryOverview;
  final List<TopProduct> topProducts;
  final List<SalesTrendPoint> salesTrend;
  final List<CategoryBreakdownSlice> categoryBreakdown;
  final List<RecentTransaction> recentTransactions;
  final DateTime generatedAt;
}
