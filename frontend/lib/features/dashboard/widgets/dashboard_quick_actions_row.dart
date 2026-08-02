import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';

/// One Quick Action card's content and behavior — a plain data holder so
/// [DashboardQuickActionsRow] itself owns no navigation decisions.
class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// The Quick Actions section — large horizontally-scrollable cards (icon,
/// title, subtitle, a small arrow) instead of a static grid, so the row
/// itself feels like an action surface rather than a dashboard tile.
class DashboardQuickActionsRow extends StatelessWidget {
  const DashboardQuickActionsRow({required this.items, super.key});

  final List<QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 152,
            child: AppCard(
              onTap: item.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child:
                            Icon(item.icon, color: AppColors.primary, size: 22),
                      ),
                      const Icon(LucideIcons.arrowUpRight,
                          size: 16, color: AppColors.textGrey),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.title,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
