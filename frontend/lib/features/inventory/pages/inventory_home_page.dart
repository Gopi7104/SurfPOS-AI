import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/skeleton_box.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';
import '../models/inventory_failure.dart';
import '../providers/inventory_providers.dart';
import 'add_product_page.dart';
import 'categories_page.dart';
import 'product_list_page.dart';

/// The Inventory tab's landing screen — summary stats + quick actions,
/// mirroring the Dashboard's own "home" philosophy. Full browsing/search
/// lives one level down, on [ProductListPage].
class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final statsAsync = ref.watch(inventoryStatsProvider(uid));

    // A caller with no merchant/store yet (onboarding not complete) gets a 404 from every
    // Inventory endpoint (merchantId can't be resolved) — that's expected, not a real error, so
    // it gets the same "finish onboarding first" prompt as the Dashboard's own empty state,
    // rather than a scary "something went wrong" or (worse) a skeleton stuck loading forever.
    final notOnboarded =
        statsAsync.hasError && statsAsync.error is NotFoundApiException;

    return Scaffold(
      appBar: const AppTopBar(title: 'Inventory'),
      body: RefreshIndicator(
        // Wraps both branches, not just the loaded one — IndexedStack keeps this tab mounted
        // (and its provider cached) even while the merchant finishes onboarding on another tab,
        // so pull-to-refresh is the only way back to real content without an app restart.
        onRefresh: () async => ref.invalidate(inventoryStatsProvider(uid)),
        child: notOnboarded
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: EmptyState(
                      icon: LucideIcons.building2,
                      title: 'Complete Merchant Onboarding',
                      message:
                          'Submit your merchant application to start managing inventory.',
                      actionLabel: 'Start Onboarding',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const MerchantOnboardingWizardPage()),
                      ),
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text('Overview', style: AppTypography.headingSM),
                  const SizedBox(height: AppSpacing.sm),
                  switch (statsAsync) {
                    AsyncData(value: final stats) => _StatsRow(stats: stats),
                    AsyncError(:final error) => ErrorState(
                        message: InventoryFailure.fromException(error).message,
                        onRetry: () =>
                            ref.invalidate(inventoryStatsProvider(uid)),
                      ),
                    _ => const _StatsRowSkeleton(),
                  },
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    title: 'Quick Actions',
                    child: Column(
                      children: [
                        _QuickActionTile(
                          icon: LucideIcons.plusCircle,
                          label: 'Add Product',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AddProductPage()),
                          ),
                        ),
                        _QuickActionTile(
                          icon: LucideIcons.package,
                          label: 'View All Products',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ProductListPage()),
                          ),
                        ),
                        _QuickActionTile(
                          icon: LucideIcons.tag,
                          label: 'Categories',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CategoriesPage()),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final InventoryStats stats;

  @override
  Widget build(BuildContext context) {
    final totalLabel = stats.isApproximate
        ? '${stats.totalProducts}+'
        : '${stats.totalProducts}';
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Total Products',
                value: totalLabel,
                color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
              label: 'Low Stock',
              value: '${stats.lowStockCount}',
              color: AppColors.warning),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
              label: 'Out of Stock',
              value: '${stats.outOfStockCount}',
              color: AppColors.error),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.headingLG.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label,
              style: AppTypography.caption.copyWith(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: AppCard(child: SkeletonBox(height: 48))),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: AppCard(child: SkeletonBox(height: 48))),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: AppCard(child: SkeletonBox(height: 48))),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: AppColors.primary),
            title: Text(label, style: AppTypography.bodyLG),
            trailing: const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.textGrey),
            onTap: onTap,
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
