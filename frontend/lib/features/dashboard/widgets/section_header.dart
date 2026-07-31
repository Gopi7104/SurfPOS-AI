import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Title (+ optional trailing widget, e.g. a "See all" action) above every
/// Dashboard section — Merchant Information, Today's Business Summary,
/// Quick Actions, Recent Activity, System Status.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headingSM),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
