import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/section_card.dart';

/// A titled label/value block on Customer Details (Profile, Address,
/// Loyalty, ...) — a thin composition of the shared [SectionCard], same
/// role `_MerchantInformationCard` plays on the Dashboard, but generic
/// enough for every info block this page needs rather than one card per
/// section.
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    required this.title,
    required this.rows,
    this.trailing,
    super.key,
  });

  final String title;
  final List<(String label, String? value)> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: trailing,
      child: Column(
        children: [
          for (final row in rows) _InfoRow(label: row.$1, value: row.$2)
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
