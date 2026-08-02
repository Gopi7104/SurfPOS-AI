import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/headers/section_header.dart';

/// Section 12's own styling of [SettingsSection] — a "DEV" [StatusChip]
/// beside the title, since this section only ever renders when
/// `AppEnvironment.current.isDevelopment` (see `SettingsHomePage`). Built
/// on the same shared [AppCard]/[SectionHeader]/[StatusChip] every other
/// card in this app uses.
class DeveloperCard extends StatelessWidget {
  const DeveloperCard({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: title,
            trailing: const StatusChip(label: 'DEV', tone: StatusTone.warning),
          ),
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
