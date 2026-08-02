import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/customer_query.dart';

/// Customer List's filter chip row — one chip per [CustomerFilter], same
/// [FilterChip] styling `InventoryFilterBar`/Reports' `ReportFilterBar`
/// already established.
class CustomerFilterBar extends StatelessWidget {
  const CustomerFilterBar({
    required this.selected,
    required this.onFilterSelected,
    super.key,
  });

  final CustomerFilter selected;
  final ValueChanged<CustomerFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in CustomerFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _FilterChip(
                label: filter.label,
                selected: selected == filter,
                onSelected: () => onFilterSelected(filter),
              ),
            ),
        ],
      ),
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
