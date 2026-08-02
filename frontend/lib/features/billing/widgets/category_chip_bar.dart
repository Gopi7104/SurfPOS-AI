import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Sticky horizontal category filter for the Billing product grid — "All"
/// plus whatever categories the catalog currently has. Visual sibling of
/// Inventory's own `InventoryFilterBar` chip, kept standalone here since
/// Billing only ever needs the category dimension, never Inventory's
/// stock/sort controls.
class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _Chip(
              label: 'All',
              selected: selectedCategory == null,
              onTap: () => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _Chip(
                label: category,
                selected: selectedCategory == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            label,
            style: AppTypography.bodySM.copyWith(
              color: selected ? AppColors.white : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
