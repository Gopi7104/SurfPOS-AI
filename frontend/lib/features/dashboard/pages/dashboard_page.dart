import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/animations/fade_slide_in.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';
import '../models/dashboard_state.dart';
import '../providers/dashboard_low_stock_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/business_insights_section.dart';
import '../widgets/business_metrics_bento.dart';
import '../widgets/dashboard_activity_empty_state.dart';
import '../widgets/dashboard_hero_section.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/dashboard_quick_actions_row.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/payment_breakdown_section.dart';
import '../widgets/recent_transactions_section.dart';
import '../widgets/revenue_chart_section.dart';
import '../widgets/sales_trend_section.dart';
import '../widgets/top_selling_products_section.dart';

/// Tab indices in [AppMainScaffold.items] (Dashboard, Billing, Inventory,
/// Reports, Customers, Settings) — kept here (not re-exported from the
/// shell) since only the Dashboard's Quick Actions need to know them.
class DashboardTabTargets {
  const DashboardTabTargets._();
  static const billing = 1;
  static const inventory = 2;
  static const analytics = 3;
  static const customers = 4;
  static const settings = 5;
}

/// The Merchant Dashboard — the app's home screen, redesigned (Phase
/// UI/UX 2) around one gradient hero card as the visual focus, dynamic
/// insight cards, a horizontally-scrollable quick actions row, and an
/// asymmetric "bento" metrics layout, in place of the old plain banner +
/// four identical stat cards. Real, live figures still come from
/// [DashboardController] (merchant/store), Inventory, and Customers, all
/// read-only exactly as before; every sales/revenue/transaction-shaped
/// section is sourced from [DemoDataController]'s generated snapshot when
/// one exists, or collapses into one illustrated empty state when it
/// doesn't. No business logic lives here — this widget only renders state
/// and delegates actions (retry, refresh, tab navigation, demo generation)
/// to the relevant controller.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({this.onNavigateToTab, super.key});

  /// Lets Quick Actions switch the shell's active tab. `null` in contexts
  /// where the page isn't hosted inside the tab shell (e.g. widget tests).
  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The family key IS the isolation boundary — watching by uid (not just watching
    // authControllerProvider for a display name) means a different signed-in user gets a
    // completely separate DashboardController instance/cache, never this one's stale value.
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      // Only reachable for a brief instant around sign-out/sign-in, before routing moves away
      // from the shell — never render stale merchant data while waiting that out.
      return const AppFullScreenLoader();
    }

    final provider = dashboardControllerProvider(uid);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: switch (state) {
        // DashboardLoadingSkeleton is itself a scrollable ListView — passed directly, never
        // wrapped in _scrollable()'s SingleChildScrollView (nesting two scrollables without a
        // bounded height between them throws "Vertical viewport was given unbounded height").
        AsyncLoading() when !state.hasValue => const DashboardLoadingSkeleton(),
        AsyncError() when !state.hasValue => _scrollable(
            ErrorState(
              message:
                  'Could not load your Merchant Dashboard. Please check your connection and try again.',
              onRetry: notifier.refresh,
            ),
          ),
        _ => _DashboardBody(
            uid: uid, data: state.value!, onNavigateToTab: onNavigateToTab),
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

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody(
      {required this.uid, required this.data, this.onNavigateToTab});

  final String uid;
  final DashboardState data;
  final ValueChanged<int>? onNavigateToTab;

  Future<void> _generateDemoData(WidgetRef ref) {
    return ref.read(demoDataControllerProvider(uid).notifier).generate(
          merchantName: data.merchant?.name,
          storeName: data.store?.name,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!data.hasMerchant) {
      return DashboardPage._scrollable(
        EmptyState(
          icon: LucideIcons.building2,
          title: 'Complete Merchant Onboarding',
          message: 'Submit your merchant application to unlock your Dashboard.',
          actionLabel: 'Start Onboarding',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const MerchantOnboardingWizardPage()),
          ),
        ),
      );
    }

    final displayName =
        ref.watch(authControllerProvider).valueOrNull?.displayName;
    final demo = ref.watch(demoDataControllerProvider(uid)).valueOrNull;
    final customerStats = ref.watch(customerStatsProvider(uid)).valueOrNull;
    final realLowStock =
        ref.watch(dashboardLowStockProvider(uid)).valueOrNull ?? const [];

    final avatarLabel = displayName?.isNotEmpty == true
        ? displayName!
        : (data.merchant?.name?.isNotEmpty == true
            ? data.merchant!.name!
            : 'S');

    final lowStockRows = demo != null
        ? [
            for (final product in demo.lowStockProducts.take(6))
              (name: product.name, remaining: product.stockQuantity)
          ]
        : [
            for (final product in realLowStock)
              (name: product.name, remaining: product.stockQuantity)
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl * 2),
      children: [
        FadeSlideIn(
          child: DashboardHeroSection(
            merchantName: data.merchant?.name,
            storeName: data.store?.name,
            avatarLabel: avatarLabel,
            todayRevenue: demo?.todaySales ?? 0,
            revenueGrowth: demo?.todaySalesGrowth,
            todayOrders: demo?.todayOrders ?? 0,
            averageOrderValue: demo?.todayAverageOrderValue ?? 0,
            customersCount:
                demo?.customersCount ?? (customerStats?.totalCustomers ?? 0),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          delay: const Duration(milliseconds: 40),
          child: DashboardQuickActionsRow(items: [
            QuickActionItem(
              icon: LucideIcons.receipt,
              title: 'New Sale',
              subtitle: 'Start billing',
              onTap: () => onNavigateToTab?.call(DashboardTabTargets.billing),
            ),
            QuickActionItem(
              icon: LucideIcons.package,
              title: 'Inventory',
              subtitle: 'Manage products',
              onTap: () => onNavigateToTab?.call(DashboardTabTargets.inventory),
            ),
            QuickActionItem(
              icon: LucideIcons.barChart3,
              title: 'Reports',
              subtitle: 'Business analytics',
              onTap: () => onNavigateToTab?.call(DashboardTabTargets.analytics),
            ),
            QuickActionItem(
              icon: LucideIcons.users,
              title: 'Customers',
              subtitle: 'Loyalty',
              onTap: () => onNavigateToTab?.call(DashboardTabTargets.customers),
            ),
            QuickActionItem(
              icon: LucideIcons.settings,
              title: 'Settings',
              subtitle: 'Store settings',
              onTap: () => onNavigateToTab?.call(DashboardTabTargets.settings),
            ),
          ]),
        ),
        if (demo != null) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: BusinessInsightsSection(insights: demo.insights),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: BusinessMetricsBento(
            todaySales: demo?.todaySales ?? 0,
            todayOrders: demo?.todayOrders ?? 0,
            averageOrderValue: demo?.todayAverageOrderValue ?? 0,
            customersCount:
                demo?.customersCount ?? (customerStats?.totalCustomers ?? 0),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (demo == null) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: DashboardActivityEmptyState(
              onGenerateDemo: AppEnvironment.current.isDevelopment
                  ? () => _generateDemoData(ref)
                  : null,
            ),
          ),
        ] else ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: RevenueChartSection(trendFor: demo.revenueTrend),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: SalesTrendSection(points: demo.salesTrend),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: PaymentBreakdownSection(slices: demo.paymentBreakdown),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: TopSellingProductsSection(
                products: demo.bestSellers.take(5).toList()),
          ),
        ],
        if (lowStockRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: LowStockSection(
              rows: lowStockRows,
              onRestock: () =>
                  onNavigateToTab?.call(DashboardTabTargets.inventory),
            ),
          ),
        ],
        if (demo != null) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: RecentTransactionsSection(
                transactions: demo.recentTransactions),
          ),
        ],
      ],
    );
  }
}
