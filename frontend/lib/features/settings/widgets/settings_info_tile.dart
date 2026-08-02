import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// A read-only label/value row — Version, Build Number, Last Sync Time,
/// API Base URL, Merchant ID, ... — mirrors `MerchantInfoTile`'s exact
/// shape (this module's own copy rather than importing Dashboard's, since
/// Dashboard is a restricted feature this module must not depend on).
class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile(
      {required this.label, this.value, this.trailing, super.key});

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
          Text(label,
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: trailing ??
                Text(
                  value ?? '—',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySM
                      .copyWith(fontWeight: FontWeight.w600),
                ),
          ),
        ],
      ),
    );
  }
}
