import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';

/// Section 13's own styling of [SettingsSection] — an error-tinted border
/// and title, so destructive actions (Clear Cache, Reset Settings, Delete
/// Local Data, Logout, Delete Account) never blend in with the rest of
/// Settings. Built on the same shared [AppCard]/[SectionHeader] every
/// other card in this app uses, just with error-toned styling — not a
/// new card implementation.
class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Danger Zone'),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}
