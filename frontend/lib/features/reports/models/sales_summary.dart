/// Sales Summary section KPIs — Today/This Week/This Month/Total Revenue.
///
/// Every `*Growth` field is the percent change vs. the equivalent prior
/// window (e.g. [todaySalesGrowth] vs. yesterday) and is `null`, not `0`,
/// when there is no prior window to compare against yet — see
/// [ReportsRepositoryImpl]'s header comment for why that's the case for
/// every merchant today. `null` means "no trend to show" to the UI
/// ([SummaryCard] renders no trend pill at all), whereas `0` would falsely
/// claim "flat, unchanged".
class SalesSummary {
  const SalesSummary({
    required this.todaySales,
    this.todaySalesGrowth,
    required this.thisWeekSales,
    this.thisWeekGrowth,
    required this.thisMonthSales,
    this.thisMonthGrowth,
    required this.totalRevenue,
    this.totalRevenueGrowth,
  });

  final double todaySales;
  final double? todaySalesGrowth;
  final double thisWeekSales;
  final double? thisWeekGrowth;
  final double thisMonthSales;
  final double? thisMonthGrowth;
  final double totalRevenue;
  final double? totalRevenueGrowth;

  factory SalesSummary.empty() => const SalesSummary(
        todaySales: 0,
        thisWeekSales: 0,
        thisMonthSales: 0,
        totalRevenue: 0,
      );
}
