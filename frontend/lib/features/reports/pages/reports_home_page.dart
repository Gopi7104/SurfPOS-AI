import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/animations/fade_slide_in.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../demo_data/models/demo_business_snapshot.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../controllers/reports_controller.dart';
import '../models/recent_transaction.dart';
import '../models/reports_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/best_sellers_card.dart';
import '../widgets/business_health_score_card.dart';
import '../widgets/business_insights_card.dart';
import '../widgets/category_performance_card.dart';
import '../widgets/export_actions_card.dart';
import '../widgets/inventory_health_card.dart';
import '../widgets/kpi_showcase_card.dart';
import '../widgets/peak_hours_card.dart';
import '../widgets/analytics_hero_header.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/reports_empty_state.dart';
import '../widgets/reports_loading_skeleton.dart';
import '../widgets/revenue_breakdown_card.dart';
import '../widgets/sales_trend_card.dart';
import '../widgets/transaction_tile.dart';

/// The Reports tab's root screen — redesigned (Phase UI/UX 6) into a
/// premium Business Intelligence dashboard, matching the Dashboard/
/// Billing/Payment/Receipt/Inventory/Settings redesign. Read-only, same
/// shape as [DashboardPage]: every real figure still comes from
/// [ReportsController]'s [ReportsState] (period filter, Inventory
/// Overview) exactly as before; every sales/revenue/transaction-shaped
/// section is sourced from [DemoDataController]'s generated snapshot when
/// one exists — the same "demo data populates the redesigned UI naturally"
/// rule the redesigned Dashboard already established — or collapses into
/// one illustrated empty state when it doesn't. No business logic lives
/// here: this widget only renders state and delegates actions (retry,
/// refresh, filter change) to the existing controllers.
///
/// Phase CRM-2: every sales-shaped figure above is real once at least one
/// sale has been recorded (`ReportsController`'s own `ReportsSnapshot`,
/// now backed by `SalesLedgerRepository` — see
/// `ReportsRepositoryImpl`'s header comment). Demo data still wins when
/// present, unchanged from before, purely so a merchant exploring the app
/// pre-launch keeps seeing a fully populated UI.
class ReportsHomePage extends ConsumerWidget {
  const ReportsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const AppFullScreenLoader();
    }

    final provider = reportsControllerProvider(uid);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: switch (state) {
        AsyncLoading() when !state.hasValue => const ReportsLoadingSkeleton(),
        AsyncError() when !state.hasValue => _scrollable(
            ErrorState(
              message:
                  'Could not load your Reports. Please check your connection and try again.',
              onRetry: notifier.refresh,
            ),
          ),
        _ => _ReportsBody(uid: uid, data: state.value!, notifier: notifier),
      },
    );
  }

  static Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody(
      {required this.uid, required this.data, required this.notifier});

  final String uid;
  final ReportsState data;
  final ReportsController notifier;

  /// Last 7 entries of whatever daily trend history is available — the
  /// same "slice what already exists, never fabricate more" rule
  /// [SalesTrendCard] itself follows for wider windows.
  List<double> _recentAmounts(List<DemoTrendPoint> points, int count) {
    if (points.length <= count) return [for (final p in points) p.amount];
    return [for (final p in points.sublist(points.length - count)) p.amount];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = data.snapshot;
    final demo = ref.watch(demoDataControllerProvider(uid)).valueOrNull;
    final customerStats = ref.watch(customerStatsProvider(uid)).valueOrNull;
    final dashboard = ref.watch(dashboardControllerProvider(uid)).valueOrNull;
    final displayName =
        ref.watch(authControllerProvider).valueOrNull?.displayName;

    final merchantName = dashboard?.merchant?.name;
    final avatarLabel = displayName?.isNotEmpty == true
        ? displayName!
        : (merchantName?.isNotEmpty == true ? merchantName! : 'S');

    final hasActivity = demo != null ||
        snapshot.salesSummary.totalRevenue > 0 ||
        snapshot.topProducts.isNotEmpty ||
        snapshot.recentTransactions.isNotEmpty;

    final salesTrendPoints = demo != null
        ? [for (final p in demo.salesTrend) (label: p.label, amount: p.amount)]
        : [
            for (final p in snapshot.salesTrend)
              (label: p.label, amount: p.amount)
          ];

    final breakdownSlices = demo != null
        ? [
            for (final s in demo.paymentBreakdown)
              (label: s.method, amount: s.amount, percentage: s.percentage)
          ]
        : [
            for (final s in snapshot.paymentBreakdown)
              (label: s.method, amount: s.amount, percentage: s.percentage)
          ];

    final bestSellerRows = demo != null
        ? _demoBestSellerRows(demo)
        : [
            for (final p in snapshot.topProducts)
              (
                name: p.name,
                category: p.category,
                unitsSold: p.unitsSold,
                revenue: p.revenue,
                progress: p.progress,
              )
          ];

    final recentTransactions =
        demo?.recentTransactions ?? snapshot.recentTransactions;

    var delay = 0;
    Duration next() {
      final d = Duration(milliseconds: delay);
      delay += 20;
      return d;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl * 2),
      children: [
        FadeSlideIn(
          delay: next(),
          child: AnalyticsHeroHeader(
            merchantName: merchantName,
            avatarLabel: avatarLabel,
            todaySales: demo?.todaySales ?? snapshot.salesSummary.todaySales,
            todaySalesGrowth: demo?.todaySalesGrowth ??
                snapshot.salesSummary.todaySalesGrowth,
            thisWeekSales:
                demo?.thisWeekSales ?? snapshot.salesSummary.thisWeekSales,
            thisWeekGrowth:
                demo?.thisWeekGrowth ?? snapshot.salesSummary.thisWeekGrowth,
            thisMonthSales:
                demo?.thisMonthSales ?? snapshot.salesSummary.thisMonthSales,
            thisMonthGrowth:
                demo?.thisMonthGrowth ?? snapshot.salesSummary.thisMonthGrowth,
            totalRevenue:
                demo?.totalRevenue ?? snapshot.salesSummary.totalRevenue,
            // Neither `SalesSummary` nor `DemoBusinessSnapshot` has a
            // meaningful "growth vs. what" baseline for an all-time total —
            // real `totalRevenueGrowth` is always null today (see
            // `SalesSummary.empty()`); left as-is rather than substituting
            // an unrelated window's growth figure.
            totalRevenueGrowth: snapshot.salesSummary.totalRevenueGrowth,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          delay: next(),
          child: ReportFilterBar(
            selected: data.period,
            customRange: data.customRange,
            onPeriodSelected: (period, {customRange}) =>
                notifier.changePeriod(period, customRange: customRange),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          delay: next(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Key Metrics'),
              Builder(builder: (context) {
                final revenue =
                    demo?.todaySales ?? snapshot.salesSummary.todaySales;
                final revenueGrowth = demo?.todaySalesGrowth ??
                    snapshot.salesSummary.todaySalesGrowth;
                final customersCount =
                    (demo?.customersCount ?? customerStats?.totalCustomers ?? 0)
                        .toDouble();
                final growth = demo?.thisWeekGrowth ??
                    snapshot.salesSummary.thisWeekGrowth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KpiHighlightCard(
                      label: 'Revenue',
                      icon: Icons.attach_money_rounded,
                      value: revenue,
                      formatter: (v) => '\$${v.toStringAsFixed(0)}',
                      growthPercent: revenueGrowth,
                      insight: revenueGrowth == null
                          ? null
                          : '${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth.toStringAsFixed(0)}% vs yesterday',
                      sparklineValues: demo != null
                          ? _recentAmounts(demo.salesTrend, 7)
                          : const [],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: KpiCompactCard(
                              label: 'Orders',
                              icon: Icons.shopping_bag_rounded,
                              value: (demo?.todayOrders ??
                                      snapshot.orderSummary.todayOrders)
                                  .toDouble(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: KpiCompactCard(
                              label: 'Customers',
                              icon: Icons.people_alt_rounded,
                              value: customersCount,
                              insight: customerStats == null
                                  ? null
                                  : '${customerStats.newThisMonth} new this month',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    KpiMediumCard(
                      label: 'Profit',
                      icon: Icons.trending_up_rounded,
                      value: demo?.totalProfit,
                      formatter: (v) => '\$${v.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    KpiWideCard(
                      label: 'Average Order Value',
                      icon: Icons.calculate_rounded,
                      value: demo?.todayAverageOrderValue ??
                          snapshot.orderSummary.averageOrderValue,
                      formatter: (v) => '\$${v.toStringAsFixed(0)}',
                      sparklineValues: demo != null
                          ? _recentAmounts(demo.salesTrend, 7)
                          : const [],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    KpiWideCard(
                      label: 'Growth',
                      icon: Icons.show_chart_rounded,
                      value: growth,
                      formatter: (v) => '${v.toStringAsFixed(0)}%',
                      insight: growth == null
                          ? null
                          : (growth >= 0
                              ? 'Trending up this week'
                              : 'Trending down this week'),
                      progressValue: growth == null
                          ? null
                          : (growth.abs() / 100).clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      children: [
                        KpiStatPill(
                            label: 'Refund Rate',
                            icon: Icons.assignment_return_rounded),
                        SizedBox(width: AppSpacing.sm),
                        KpiStatPill(
                            label: 'Inventory Value',
                            icon: Icons.inventory_2_rounded),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          delay: next(),
          child: InventoryHealthCard(
            lowStockCount: snapshot.inventoryOverview.lowStockCount,
            outOfStockCount: snapshot.inventoryOverview.outOfStockCount,
          ),
        ),
        if (!hasActivity) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(delay: next(), child: const ReportsEmptyState()),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
              delay: next(), child: SalesTrendCard(points: salesTrendPoints)),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
              delay: next(),
              child: RevenueBreakdownCard(slices: breakdownSlices)),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
              delay: next(), child: BestSellersCard(rows: bestSellerRows)),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: next(),
            child: BusinessInsightsCard(insights: demo?.insights ?? const []),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: next(),
            child: _RecentTransactionsSection(transactions: recentTransactions),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(delay: next(), child: const CategoryPerformanceCard()),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(delay: next(), child: const PeakHoursCard()),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(delay: next(), child: const BusinessHealthScoreCard()),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(delay: next(), child: const ExportActionsCard()),
      ],
    );
  }

  List<
      ({
        String name,
        String? category,
        int unitsSold,
        double revenue,
        double progress
      })> _demoBestSellerRows(DemoBusinessSnapshot demo) {
    final sellers = demo.bestSellers.where((p) => p.unitsSold > 0).toList();
    if (sellers.isEmpty) return const [];
    final maxUnits = sellers.first.unitsSold;
    return [
      for (final p in sellers)
        (
          name: p.name,
          category: p.category,
          unitsSold: p.unitsSold,
          revenue: p.revenue,
          progress: maxUnits == 0 ? 0.0 : p.unitsSold / maxUnits,
        ),
    ];
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.transactions});

  final List<RecentTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Recent Transactions'),
        for (final transaction in transactions.take(10)) ...[
          TransactionTile(transaction: transaction),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
