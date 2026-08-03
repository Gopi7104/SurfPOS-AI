import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/animations/fade_slide_in.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../ai/widgets/surf_ai_floating_button.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../../demo_data/models/demo_business_snapshot.dart';
import '../../demo_data/models/payment_breakdown_slice.dart';
import '../../demo_data/models/revenue_period.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';
import '../../reports/models/recent_transaction.dart';
import '../../reports/models/sales_ledger_snapshot.dart';
import '../../reports/providers/sales_ledger_providers.dart';
import '../models/dashboard_state.dart';
import '../providers/dashboard_low_stock_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/business_insights_section.dart';
import '../widgets/dashboard_activity_empty_state.dart';
import '../widgets/dashboard_hero_section.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/dashboard_quick_actions_row.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/payment_breakdown_section.dart';
import '../widgets/recent_transactions_section.dart';
import '../widgets/revenue_chart_section.dart';
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
/// UI/UX 2, refined Phase UI/UX 3) around one gradient hero card as the
/// visual focus, dynamic insight cards, and a horizontally-scrollable
/// quick actions row, in place of the old plain banner + four identical
/// stat cards. Phase UI/UX 3 also dropped two sections that duplicated
/// data shown elsewhere on this same screen: the "bento" metrics grid
/// (Today's Sales/Orders/Average Order/Customers — all already in the
/// hero's own stat pills) and the 14-day Sales Trend line chart (the same
/// revenue-over-time data the Revenue Chart above it already plots, just
/// at a fixed bucketing instead of the Revenue Chart's own Today/Week/
/// Month toggle) — one section per distinct piece of information, not two
/// showing the same numbers back to back. Real, live figures still come from
/// [DashboardController] (merchant/store), Inventory, and Customers, all
/// read-only exactly as before; every sales/revenue/transaction-shaped
/// section prefers real data from [SalesLedgerSnapshot] (Phase CRM-2 —
/// populated the instant Payments' success hook records a completed sale)
/// once at least one real sale exists, falls back to
/// [DemoDataController]'s generated snapshot when it doesn't, or collapses
/// into one illustrated empty state when neither does. No business logic
/// lives here — this widget only renders state and delegates actions
/// (retry, refresh, tab navigation, demo generation) to the relevant
/// controller.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({this.onNavigateToTab, this.scrollController, super.key});

  /// Lets Quick Actions switch the shell's active tab. `null` in contexts
  /// where the page isn't hosted inside the tab shell (e.g. widget tests).
  final ValueChanged<int>? onNavigateToTab;

  /// Externally-owned controller for the main content `ListView` — lets
  /// [MainShellPage] drive Dashboard's scroll position from outside (see
  /// [AppFab.onVerticalDrag]). `null` (the default, and what every widget
  /// test uses) falls back to an internally-owned controller, unchanged
  /// from before.
  final ScrollController? scrollController;

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

    // Mirrors `MainShellPage._handleFabVerticalDrag` exactly — see
    // `SurfAiFloatingButton.onVerticalDrag`'s header comment for why this
    // button needs the same forwarding the "New Sale" FAB already has.
    void handleFabVerticalDrag(double dy) {
      if (scrollController == null || !scrollController!.hasClients) return;
      final position = scrollController!.position;
      scrollController!.jumpTo(
        (position.pixels - dy)
            .clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: notifier.refresh,
          child: switch (state) {
            // DashboardLoadingSkeleton is itself a scrollable ListView — passed directly, never
            // wrapped in _scrollable()'s SingleChildScrollView (nesting two scrollables without a
            // bounded height between them throws "Vertical viewport was given unbounded height").
            AsyncLoading() when !state.hasValue =>
              const DashboardLoadingSkeleton(),
            AsyncError() when !state.hasValue => _scrollable(
                ErrorState(
                  message:
                      'Could not load your Merchant Dashboard. Please check your connection and try again.',
                  onRetry: notifier.refresh,
                ),
              ),
            _ => _DashboardBody(
                uid: uid,
                data: state.value!,
                onNavigateToTab: onNavigateToTab,
                scrollController: scrollController),
          },
        ),
        // Dashboard-only, deliberately: SurfAI's floating entry point is never shown on
        // Billing/Inventory/Reports/Customers/Settings (each has its own primary FAB/action, or
        // none at all) — see docs/22_DEVELOPMENT_ROADMAP.md Phase AI-3. Positioned here (inside
        // this page) rather than in the shared `AppMainScaffold` FAB slot, since that slot is
        // already the centered "New Sale" FAB (`FloatingActionButtonLocation.centerFloat`) and
        // can only ever hold one widget; sitting above it, offset right, keeps both visible
        // without overlapping, and a small corner overlay never blocks cards or scrolling.
        Positioned(
          bottom: 100,
          right: AppSpacing.md,
          child: SurfAiFloatingButton(
            onVerticalDrag: handleFabVerticalDrag,
          ),
        ),
      ],
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

class _DashboardBody extends ConsumerStatefulWidget {
  const _DashboardBody(
      {required this.uid,
      required this.data,
      this.onNavigateToTab,
      this.scrollController});

  final String uid;
  final DashboardState data;
  final ValueChanged<int>? onNavigateToTab;
  final ScrollController? scrollController;

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  // A dedicated ScrollController — not a bare `ListView(...)` with no
  // controller. Without one, `ScrollView.primary` defaults to `true` and
  // this ListView silently inherits the single `PrimaryScrollController`
  // that Flutter's Navigator creates ONE of per route (see
  // `_ModalScopeState` in `widgets/routes.dart`). Since `MainShellPage`
  // keeps all 6 tabs mounted at once in an `IndexedStack` within that SAME
  // route, every tab's root `ListView` — Dashboard, Billing, Inventory,
  // Reports, Customers, Settings — would otherwise all attach to that one
  // shared controller. Giving Dashboard its own controller (and
  // `primary: false`) makes it the sole, unambiguous owner of its own
  // scroll position, immune to any cross-tab interference — "exactly one
  // primary vertical scrollable" per screen.
  //
  // Usually created and owned right here — except `MainShellPage` supplies
  // its own externally so it can drive this same position when a drag
  // starts on the floating "New Sale" button instead of on the list itself
  // (see `AppFab.onVerticalDrag`); an externally-supplied controller is
  // the caller's to dispose, not ours.
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  String get uid => widget.uid;
  DashboardState get data => widget.data;
  ValueChanged<int>? get onNavigateToTab => widget.onNavigateToTab;

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _generateDemoData(WidgetRef ref) {
    return ref.read(demoDataControllerProvider(uid).notifier).generate(
          merchantName: data.merchant?.name,
          storeName: data.store?.name,
        );
  }

  @override
  Widget build(BuildContext context) {
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
    final ledger = ref.watch(salesLedgerSnapshotProvider(uid)).valueOrNull;
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

    // Real sales (Phase CRM-2) win over demo data the instant at least one
    // payment has ever been recorded — demo data only fills the UI in for
    // exploration before that. See this class's header comment.
    final hasRealSales = ledger != null;
    final hasActivity = hasRealSales || demo != null;
    final todayRevenue =
        hasRealSales ? ledger.todaySales : (demo?.todaySales ?? 0);
    final revenueGrowth =
        hasRealSales ? ledger.todaySalesGrowth : demo?.todaySalesGrowth;
    final todayOrders =
        hasRealSales ? ledger.todayOrders : (demo?.todayOrders ?? 0);
    final averageOrderValue = hasRealSales
        ? ledger.todayAverageOrderValue
        : (demo?.todayAverageOrderValue ?? 0);

    List<DemoTrendPoint> revenueTrendFor(RevenuePeriod period) {
      if (!hasRealSales) return demo?.revenueTrend(period) ?? const [];
      final points = switch (period) {
        RevenuePeriod.today => ledger.revenueTrendToday(),
        RevenuePeriod.week => ledger.revenueTrendThisWeek(),
        RevenuePeriod.month => ledger.revenueTrendThisMonth(),
      };
      return [
        for (final p in points) DemoTrendPoint(label: p.label, amount: p.amount)
      ];
    }

    final paymentBreakdownSlices = hasRealSales
        ? [
            for (final s in ledger.paymentBreakdown)
              PaymentBreakdownSlice(
                  method: s.method, amount: s.amount, percentage: s.percentage)
          ]
        : (demo?.paymentBreakdown ?? const <PaymentBreakdownSlice>[]);

    final recentTransactions = hasRealSales
        ? [
            for (final r in ledger.mostRecent.take(20))
              RecentTransaction(
                receiptNumber: r.receiptNumber,
                customerName: r.customerName,
                amount: r.total,
                status: TransactionStatus.successful,
                paymentMethod: r.paymentMethod,
                time: r.occurredAt,
              )
          ]
        : (demo?.recentTransactions ?? const <RecentTransaction>[]);

    return ListView(
      controller: _scrollController,
      primary: false,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl * 2),
      children: [
        FadeSlideIn(
          child: DashboardHeroSection(
            merchantName: data.merchant?.name,
            storeName: data.store?.name,
            avatarLabel: avatarLabel,
            todayRevenue: todayRevenue,
            revenueGrowth: revenueGrowth,
            todayOrders: todayOrders,
            averageOrderValue: averageOrderValue,
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
        if (!hasActivity) ...[
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
            child: RevenueChartSection(trendFor: revenueTrendFor),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: PaymentBreakdownSection(slices: paymentBreakdownSlices),
          ),
          // Top Selling Products stays demo-only: it renders `DemoProduct`
          // rows (stock/color-swatch fields the real sales ledger has no
          // equivalent for), so a real product's row would need fabricated
          // filler for those fields — the ledger's own real top sellers
          // are shown for real on Reports instead (see `TopProduct`).
          if (demo != null) ...[
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: TopSellingProductsSection(
                  products: demo.bestSellers.take(5).toList()),
            ),
          ],
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
        if (recentTransactions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: RecentTransactionsSection(transactions: recentTransactions),
          ),
        ],
      ],
    );
  }
}
