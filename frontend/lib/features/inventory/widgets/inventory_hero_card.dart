import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/gradient_hero_card.dart';
import '../../../core/widgets/chips/stat_pill.dart';
import '../models/product_model.dart';

/// The Inventory tab's "premium gradient card similar to the Dashboard" —
/// mirrors `DashboardHeroSection`'s composition exactly (title, one big
/// animated KPI, a row of quick-glance pills). All five figures are
/// computed here, client-side, from [items] — the same page of products
/// already loaded for the grid/list below (see
/// `InventoryHomePage`) — rather than a second fetch; [isApproximate]
/// mirrors the existing `inventoryStatsProvider`'s own "sample, not the
/// whole catalog" caveat when the list has more pages.
class InventoryHeroCard extends StatelessWidget {
  const InventoryHeroCard({
    required this.items,
    required this.isApproximate,
    super.key,
  });

  final List<ProductModel> items;
  final bool isApproximate;

  int get _lowStockCount => items.where((p) => p.isLowStock).length;
  int get _outOfStockCount => items.where((p) => p.isOutOfStock).length;
  double get _totalValue =>
      items.fold(0.0, (sum, p) => sum + p.price * p.stockQuantity);

  int get _todayAddedCount {
    final now = DateTime.now();
    return items
        .where((p) =>
            p.createdAt.year == now.year &&
            p.createdAt.month == now.month &&
            p.createdAt.day == now.day)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final totalLabel = isApproximate ? '${items.length}+' : '${items.length}';

    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: AppTypography.headingSM.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Total Inventory Value',
            style: AppTypography.caption
                .copyWith(color: AppColors.white.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 4),
          CountUpNumber(
            value: _totalValue,
            formatter: (v) => '\$${v.toStringAsFixed(0)}',
            style: AppTypography.numberXL.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatPill(value: totalLabel, label: 'Products', light: true),
              StatPill(
                  value: '$_lowStockCount', label: 'Low Stock', light: true),
              StatPill(
                  value: '$_outOfStockCount',
                  label: 'Out of Stock',
                  light: true),
              StatPill(
                  value: '$_todayAddedCount',
                  label: 'Added Today',
                  light: true),
            ],
          ),
        ],
      ),
    );
  }
}
