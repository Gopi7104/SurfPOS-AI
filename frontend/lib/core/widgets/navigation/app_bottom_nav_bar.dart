import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import 'app_nav_item.dart';

/// The bottom navigation bar (Dashboard, Billing, Inventory, Reports,
/// Customers, Settings). Flat, top-rounded, soft-shadow-lifted surface —
/// the "Start New Sale" [AppFab] floats independently above it via
/// [AppMainScaffold] rather than a Material notch, so all 5 destinations
/// stay evenly spaced. See the BOTTOM NAVIGATION design brief.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavBarItem(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textGrey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve.standard,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
