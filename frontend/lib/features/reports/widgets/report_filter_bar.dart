import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/report_period.dart';

/// Reports Home's date-range filter row — one chip per [ReportPeriod],
/// same [FilterChip] styling `InventoryFilterBar._FilterChip` already
/// established. Selecting [ReportPeriod.custom] opens the platform date
/// range picker itself rather than making every caller wire that up.
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    required this.selected,
    required this.customRange,
    required this.onPeriodSelected,
    super.key,
  });

  final ReportPeriod selected;
  final DateTimeRange? customRange;
  final void Function(ReportPeriod period, {DateTimeRange? customRange})
      onPeriodSelected;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: customRange,
    );
    if (picked != null) {
      onPeriodSelected(ReportPeriod.custom, customRange: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final period
              in ReportPeriod.values.where((p) => p != ReportPeriod.custom))
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _FilterChip(
                label: period.label,
                selected: selected == period,
                onSelected: () => onPeriodSelected(period),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _FilterChip(
              label: selected == ReportPeriod.custom && customRange != null
                  ? '${_formatDate(customRange!.start)} – ${_formatDate(customRange!.end)}'
                  : 'Custom Range',
              selected: selected == ReportPeriod.custom,
              onSelected: () => _pickCustomRange(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';
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
