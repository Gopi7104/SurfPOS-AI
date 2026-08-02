import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_gradient_header.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../controllers/reports_controller.dart';
import '../models/inventory_overview.dart';
import '../models/order_summary.dart';
import '../models/recent_transaction.dart';
import '../models/reports_state.dart';
import '../models/sales_summary.dart';
import '../models/top_product.dart';
import '../providers/reports_providers.dart';
import '../widgets/chart_card.dart';
import '../widgets/empty_reports_view.dart';
import '../widgets/pie_chart_card.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/reports_loading_skeleton.dart';
import '../widgets/summary_card.dart';
import '../widgets/top_product_tile.dart';
import '../widgets/transaction_tile.dart';

/// The Reports tab's root screen — replaces the old placeholder (Phase
/// 5.1). Read-only, same shape as [DashboardPage]: every figure comes from
/// [ReportsController]'s [ReportsState], this widget only renders it and
/// delegates actions (retry, refresh, filter change) to the controller.
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
        _ => _buildContent(context, state.value!, notifier),
      },
    );
  }

  Widget _scrollable(Widget child) {
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

  Widget _buildContent(
      BuildContext context, ReportsState data, ReportsController notifier) {
    final snapshot = data.snapshot;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      children: [
        AppGradientHeader(
          child: Text('Reports',
              style: AppTypography.headingLG.copyWith(color: AppColors.white)),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportFilterBar(
                selected: data.period,
                customRange: data.customRange,
                onPeriodSelected: (period, {customRange}) =>
                    notifier.changePeriod(period, customRange: customRange),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Sales Summary'),
              _SalesSummaryGrid(summary: snapshot.salesSummary),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Orders'),
              _OrderSummaryGrid(summary: snapshot.orderSummary),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Inventory Overview'),
              _InventoryOverviewGrid(overview: snapshot.inventoryOverview),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Top Selling Products'),
              _TopProductsList(products: snapshot.topProducts),
              const SizedBox(height: AppSpacing.lg),
              ChartCard(title: 'Sales Chart', points: snapshot.salesTrend),
              const SizedBox(height: AppSpacing.lg),
              PieChartCard(slices: snapshot.categoryBreakdown),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Recent Transactions'),
              _RecentTransactionsList(
                  transactions: snapshot.recentTransactions),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Quick Reports'),
              const _QuickReportsGrid(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesSummaryGrid extends StatelessWidget {
  const _SalesSummaryGrid({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: [
        SummaryCard(
          label: "Today's Sales",
          value: '\$${summary.todaySales.toStringAsFixed(2)}',
          icon: LucideIcons.dollarSign,
          growthPercent: summary.todaySalesGrowth,
        ),
        SummaryCard(
          label: 'This Week',
          value: '\$${summary.thisWeekSales.toStringAsFixed(2)}',
          icon: LucideIcons.calendarDays,
          growthPercent: summary.thisWeekGrowth,
        ),
        SummaryCard(
          label: 'This Month',
          value: '\$${summary.thisMonthSales.toStringAsFixed(2)}',
          icon: LucideIcons.calendarRange,
          growthPercent: summary.thisMonthGrowth,
        ),
        SummaryCard(
          label: 'Total Revenue',
          value: '\$${summary.totalRevenue.toStringAsFixed(2)}',
          icon: LucideIcons.wallet,
          growthPercent: summary.totalRevenueGrowth,
        ),
      ],
    );
  }
}

class _OrderSummaryGrid extends StatelessWidget {
  const _OrderSummaryGrid({required this.summary});

  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: [
        SummaryCard(
          label: "Today's Orders",
          value: '${summary.todayOrders}',
          icon: LucideIcons.shoppingBag,
        ),
        SummaryCard(
          label: 'Completed',
          value: '${summary.completedOrders}',
          icon: LucideIcons.checkCircle2,
        ),
        SummaryCard(
          label: 'Cancelled',
          value: '${summary.cancelledOrders}',
          icon: LucideIcons.xCircle,
        ),
        SummaryCard(
          label: 'Average Order Value',
          value: '\$${summary.averageOrderValue.toStringAsFixed(2)}',
          icon: LucideIcons.calculator,
        ),
      ],
    );
  }
}

class _InventoryOverviewGrid extends StatelessWidget {
  const _InventoryOverviewGrid({required this.overview});

  final InventoryOverview overview;

  @override
  Widget build(BuildContext context) {
    final productsLabel = overview.isApproximate
        ? '${overview.productsCount}+'
        : '${overview.productsCount}';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: [
        SummaryCard(
            label: 'Products', value: productsLabel, icon: LucideIcons.package),
        SummaryCard(
            label: 'Low Stock',
            value: '${overview.lowStockCount}',
            icon: LucideIcons.triangleAlert),
        SummaryCard(
            label: 'Out Of Stock',
            value: '${overview.outOfStockCount}',
            icon: LucideIcons.packageX),
        SummaryCard(
            label: 'Categories',
            value: '${overview.categoriesCount}',
            icon: LucideIcons.tags),
      ],
    );
  }
}

class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const AppCard(
        child:
            EmptyReportsView(message: 'No products sold in this period yet.'),
      );
    }
    return Column(
      children: [
        for (final product in products.take(10)) ...[
          TopProductTile(product: product),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList({required this.transactions});

  final List<RecentTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const AppCard(
        child: EmptyReportsView(
            message: 'No transactions recorded in this period yet.'),
      );
    }
    return Column(
      children: [
        for (final transaction in transactions.take(20)) ...[
          TransactionTile(transaction: transaction),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuickReportsGrid extends StatelessWidget {
  const _QuickReportsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: const [
        _QuickReportButton(
            icon: LucideIcons.calendarDays, label: 'Daily Report'),
        _QuickReportButton(
            icon: LucideIcons.calendarRange, label: 'Weekly Report'),
        _QuickReportButton(
            icon: LucideIcons.calendarClock, label: 'Monthly Report'),
        _QuickReportButton(
            icon: LucideIcons.fileSpreadsheet, label: 'Export CSV'),
        _QuickReportButton(icon: LucideIcons.fileText, label: 'Export PDF'),
      ],
    );
  }
}

class _QuickReportButton extends StatelessWidget {
  const _QuickReportButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming Soon')),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
