import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';

/// Export/Share actions — restyled from the old "Quick Reports" grid.
/// None of these have real functionality yet (no PDF/CSV generation or
/// print/share wiring exists for Reports specifically today — Receipt has
/// its own separate PDF/share flow, out of scope to touch here), so every
/// card stays a labeled "Coming Soon" stub, same behavior as before, just
/// restyled — no new backend/export functionality is built in this phase.
class ExportActionsCard extends StatelessWidget {
  const ExportActionsCard({super.key});

  static const _actions = [
    (icon: LucideIcons.fileText, label: 'Export PDF'),
    (icon: LucideIcons.fileSpreadsheet, label: 'Export CSV'),
    (icon: LucideIcons.printer, label: 'Print Report'),
    (icon: LucideIcons.share2, label: 'Share'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Export & Share'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.8,
          children: [
            for (final action in _actions)
              _ExportActionTile(icon: action.icon, label: action.label)
          ],
        ),
      ],
    );
  }
}

class _ExportActionTile extends StatelessWidget {
  const _ExportActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coming Soon'))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label,
              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          Text('Coming Soon',
              style: AppTypography.caption
                  .copyWith(color: AppColors.disabledText)),
        ],
      ),
    );
  }
}
