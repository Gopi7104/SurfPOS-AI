import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/inventory_query.dart';

/// The Product List's filter/sort row — stock-level chips (All/Low
/// Stock/In Stock/Out of Stock), category chips (dynamic, from whatever
/// categories currently exist in the catalog), and a sort menu covering
/// both the Sorting spec (Alphabetical/Price/Stock/Recently Updated) and
/// the Filters spec's Newest/Oldest.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({
    required this.query,
    required this.categories,
    required this.onQueryChanged,
    super.key,
  });

  final InventoryQuery query;
  final List<String> categories;
  final ValueChanged<InventoryQuery> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final filter in StockFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _FilterChip(
                    label: filter.label,
                    selected: query.stockFilter == filter,
                    onSelected: () =>
                        onQueryChanged(query.copyWith(stockFilter: filter)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _SortButton(
                  current: query.sortOption,
                  onSelected: (option) =>
                      onQueryChanged(query.copyWith(sortOption: option)),
                ),
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _FilterChip(
                    label: 'All Categories',
                    selected: query.category == null,
                    onSelected: () =>
                        onQueryChanged(query.copyWith(clearCategory: true)),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _FilterChip(
                      label: category,
                      selected: query.category == category,
                      onSelected: () =>
                          onQueryChanged(query.copyWith(category: category)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      labelStyle: AppTypography.caption.copyWith(
        color: selected ? AppColors.white : AppColors.textDark,
        fontWeight: FontWeight.w600,
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      showCheckmark: false,
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current, required this.onSelected});

  final InventorySortOption? current;
  final ValueChanged<InventorySortOption> onSelected;

  Future<void> _openSortSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<InventorySortOption>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Sort by', style: AppTypography.headingSM),
            ),
            for (final option in InventorySortOption.values)
              ListTile(
                title: Text(option.label),
                trailing: option == current
                    ? const Icon(LucideIcons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return _FilterChip(
      label: current == null ? 'Sort' : current!.label,
      selected: current != null,
      onSelected: () => _openSortSheet(context),
    );
  }
}
