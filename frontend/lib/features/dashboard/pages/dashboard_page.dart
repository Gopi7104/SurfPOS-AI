import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_gradient_header.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../merchant/data/models/merchant_application.dart';
import '../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';
import '../models/dashboard_state.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/dashboard_summary_stat_card.dart';
import '../widgets/merchant_info_tile.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

/// Tab indices in [AppMainScaffold.items] (Dashboard, Billing, Inventory,
/// Reports, Settings) — kept here (not re-exported from the shell) since
/// only the Dashboard's Quick Actions need to know them.
class DashboardTabTargets {
  const DashboardTabTargets._();
  static const billing = 1;
  static const inventory = 2;
  static const analytics = 3;
}

/// The Merchant Dashboard — the app's home screen (Phase 1, see
/// docs/22_DEVELOPMENT_ROADMAP.md). Read-only: every figure either comes
/// from the real Firebase-tracked application + live Surfboard profile
/// ([DashboardController]), or is an explicit zero placeholder for
/// not-yet-built Billing. No business logic lives here — this widget only
/// renders [DashboardState] and delegates actions (retry, refresh, tab
/// navigation) to the controller / [onNavigateToTab].
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
    final uid = ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
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
              message: 'Could not load your Merchant Dashboard. Please check your connection and try again.',
              onRetry: notifier.refresh,
            ),
          ),
        _ => _buildContent(context, ref, state.value!),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardState data) {
    if (!data.hasMerchant) {
      return _scrollable(
        EmptyState(
          icon: LucideIcons.building2,
          title: 'Complete Merchant Onboarding',
          message: 'Submit your merchant application to unlock your Dashboard.',
          actionLabel: 'Start Onboarding',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MerchantOnboardingWizardPage()),
          ),
        ),
      );
    }

    final displayName = ref.watch(authControllerProvider).valueOrNull?.displayName;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      children: [
        AppGradientHeader(
          child: Text(
            displayName?.isNotEmpty == true ? 'Welcome back, $displayName' : 'Welcome back',
            style: AppTypography.headingLG.copyWith(color: AppColors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MerchantInformationCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: "Today's Business Summary"),
              _BusinessSummaryGrid(data: data),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Quick Actions'),
              _QuickActionsGrid(onNavigateToTab: onNavigateToTab),
              const SizedBox(height: AppSpacing.lg),
              const DashboardCard(
                title: 'Recent Activity',
                child: EmptyState(
                  icon: LucideIcons.receipt,
                  title: 'Nothing here yet',
                  message: 'No transactions yet.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SystemStatusCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MerchantInformationCard extends StatelessWidget {
  const _MerchantInformationCard({required this.data});

  final DashboardState data;

  @override
  Widget build(BuildContext context) {
    final application = data.applicationStatus;

    return DashboardCard(
      title: 'Merchant Information',
      child: Column(
        children: [
          MerchantInfoTile(label: 'Merchant Name', value: data.merchant?.name),
          MerchantInfoTile(label: 'Merchant ID', value: data.merchant?.id),
          MerchantInfoTile(label: 'Store Name', value: data.store?.name),
          MerchantInfoTile(label: 'Store ID', value: data.store?.id),
          MerchantInfoTile(
            label: 'Merchant Status',
            trailing: application == null
                ? null
                : StatusChip(label: _merchantStatusLabel(application), tone: _applicationTone(application)),
          ),
          MerchantInfoTile(
            label: 'Store Status',
            trailing: data.store?.status == null
                ? null
                : StatusChip(label: data.store!.status!, tone: _storeTone(data.store!.status!)),
          ),
          MerchantInfoTile(
            label: 'Application Status',
            trailing: application == null
                ? null
                // The full descriptive copy (Merchant Status above uses the short form) —
                // Surfboard has no separate Merchant-object status field, both are genuinely
                // derived from the same applicationStatus, so only the label differs.
                : StatusChip(label: application.label, tone: _applicationTone(application)),
          ),
          MerchantInfoTile(label: 'Last Synced', value: _formatTime(data.lastSyncedAt)),
        ],
      ),
    );
  }

  String _merchantStatusLabel(ApplicationStatus status) => switch (status) {
        ApplicationStatus.merchantCreated || ApplicationStatus.applicationCompleted => 'Active',
        ApplicationStatus.applicationRejected => 'Rejected',
        ApplicationStatus.applicationExpired => 'Expired',
        ApplicationStatus.unknown => 'Unknown',
        _ => 'Pending',
      };

  StatusTone _applicationTone(ApplicationStatus status) => switch (status) {
        ApplicationStatus.merchantCreated || ApplicationStatus.applicationCompleted => StatusTone.success,
        ApplicationStatus.applicationRejected || ApplicationStatus.applicationExpired => StatusTone.error,
        ApplicationStatus.unknown => StatusTone.neutral,
        _ => StatusTone.warning,
      };

  StatusTone _storeTone(String status) =>
      status.toLowerCase().contains('active') ? StatusTone.success : StatusTone.neutral;

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _BusinessSummaryGrid extends StatelessWidget {
  const _BusinessSummaryGrid({required this.data});

  final DashboardState data;

  @override
  Widget build(BuildContext context) {
    final summary = data.businessSummary;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      // StatCard's content (icon + numberLG value + caption label) is a sliver taller than
      // 1.4 lets it be at common device widths — was overflowing by a fraction of a pixel.
      childAspectRatio: 1.2,
      children: [
        DashboardSummaryStatCard(
          label: "Today's Sales",
          value: summary.todaySales.toStringAsFixed(0),
          icon: LucideIcons.dollarSign,
        ),
        DashboardSummaryStatCard(
          label: "Today's Orders",
          value: summary.todayOrders.toString(),
          icon: LucideIcons.shoppingBag,
        ),
        DashboardSummaryStatCard(
          label: "Today's Customers",
          value: summary.todayCustomers.toString(),
          icon: LucideIcons.users,
        ),
        DashboardSummaryStatCard(
          label: 'Products',
          value: summary.productsCount.toString(),
          icon: LucideIcons.package,
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.8,
      children: [
        QuickActionCard(
          icon: LucideIcons.receipt,
          label: 'New Bill',
          onTap: () => onNavigateToTab?.call(DashboardTabTargets.billing),
        ),
        QuickActionCard(
          icon: LucideIcons.package,
          label: 'Inventory',
          onTap: () => onNavigateToTab?.call(DashboardTabTargets.inventory),
        ),
        QuickActionCard(
          icon: LucideIcons.users,
          label: 'Customers',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customers is coming soon.')),
          ),
        ),
        QuickActionCard(
          icon: LucideIcons.barChart3,
          label: 'Reports',
          onTap: () => onNavigateToTab?.call(DashboardTabTargets.analytics),
        ),
      ],
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard();

  @override
  Widget build(BuildContext context) {
    // Reaching this widget at all means the Dashboard's own load (Firebase
    // auth + backend + Surfboard round trip) already succeeded — so all
    // three are, by construction, connected. There's no separate per-service
    // health-check endpoint yet (Phase 1 scope); revisit if one is added.
    return const DashboardCard(
      title: 'System Status',
      child: Column(
        children: [
          MerchantInfoTile(label: 'Backend', trailing: StatusChip(label: 'Connected', tone: StatusTone.success)),
          MerchantInfoTile(
            label: 'Surfboard',
            trailing: StatusChip(label: 'Connected', tone: StatusTone.success),
          ),
          MerchantInfoTile(label: 'Firebase', trailing: StatusChip(label: 'Connected', tone: StatusTone.success)),
        ],
      ),
    );
  }
}
