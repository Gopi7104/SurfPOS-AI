import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/inventory_query.dart';

/// The quick filter a chip maps to — kept distinct from [InventoryQuery]
/// (which spreads the same idea across [StockFilter] and
/// [InventorySortOption]) so this bar can render one single-select row.
enum QuickFilter { all, inStock, lowStock, outOfStock, recentlyAdded }

/// Beautiful single-select quick filters — All/In Stock/Low Stock/Out of
/// Stock (backed by [InventoryQuery.stockFilter]) and Recently Added
/// (backed by [InventoryQuery.sortOption]), plus three chips the brief asks
/// for that have no backing data anywhere in this app yet (no sales
/// history, no import-source field) — shown disabled with a "Coming Soon"
/// mark rather than silently doing nothing.
class InventoryQuickFilterBar extends StatelessWidget {
  const InventoryQuickFilterBar({
    required this.query,
    required this.onQueryChanged,
    super.key,
  });

  final InventoryQuery query;
  final ValueChanged<InventoryQuery> onQueryChanged;

  QuickFilter get _selected {
    if (query.sortOption == InventorySortOption.newest) {
      return QuickFilter.recentlyAdded;
    }
    return switch (query.stockFilter) {
      StockFilter.all => QuickFilter.all,
      StockFilter.inStock => QuickFilter.inStock,
      StockFilter.lowStock => QuickFilter.lowStock,
      StockFilter.outOfStock => QuickFilter.outOfStock,
    };
  }

  void _select(QuickFilter filter) {
    switch (filter) {
      case QuickFilter.recentlyAdded:
        onQueryChanged(query.copyWith(
            sortOption: InventorySortOption.newest,
            stockFilter: StockFilter.all));
      case QuickFilter.all:
        onQueryChanged(query.copyWith(
            stockFilter: StockFilter.all, clearSortOption: true));
      case QuickFilter.inStock:
        onQueryChanged(query.copyWith(
            stockFilter: StockFilter.inStock, clearSortOption: true));
      case QuickFilter.lowStock:
        onQueryChanged(query.copyWith(
            stockFilter: StockFilter.lowStock, clearSortOption: true));
      case QuickFilter.outOfStock:
        onQueryChanged(query.copyWith(
            stockFilter: StockFilter.outOfStock, clearSortOption: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickFilterChip(
            label: 'All',
            selected: selected == QuickFilter.all,
            onTap: () => _select(QuickFilter.all),
          ),
          const SizedBox(width: AppSpacing.xs),
          _QuickFilterChip(
            label: 'In Stock',
            selected: selected == QuickFilter.inStock,
            onTap: () => _select(QuickFilter.inStock),
          ),
          const SizedBox(width: AppSpacing.xs),
          _QuickFilterChip(
            label: 'Low Stock',
            selected: selected == QuickFilter.lowStock,
            onTap: () => _select(QuickFilter.lowStock),
          ),
          const SizedBox(width: AppSpacing.xs),
          _QuickFilterChip(
            label: 'Out of Stock',
            selected: selected == QuickFilter.outOfStock,
            onTap: () => _select(QuickFilter.outOfStock),
          ),
          const SizedBox(width: AppSpacing.xs),
          _QuickFilterChip(
            label: 'Recently Added',
            selected: selected == QuickFilter.recentlyAdded,
            onTap: () => _select(QuickFilter.recentlyAdded),
          ),
          const SizedBox(width: AppSpacing.xs),
          const _QuickFilterChip(label: 'Most Sold', enabled: false),
          const SizedBox(width: AppSpacing.xs),
          const _QuickFilterChip(label: 'Imported via Barcode', enabled: false),
          const SizedBox(width: AppSpacing.xs),
          const _QuickFilterChip(label: 'Manual Entry', enabled: false),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySM.copyWith(
                    color: selected ? AppColors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(LucideIcons.clock,
                      size: 12, color: AppColors.textGrey),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
