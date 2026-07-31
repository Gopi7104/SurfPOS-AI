import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// A label/value row inside the Merchant Information card (Merchant Name,
/// Merchant ID, Store Name, ...). [trailing] lets a row show a
/// [StatusChip] instead of plain text (Merchant Status, Store Status,
/// Application Status).
class MerchantInfoTile extends StatelessWidget {
  const MerchantInfoTile({required this.label, this.value, this.trailing, super.key});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: trailing ??
                Text(
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
