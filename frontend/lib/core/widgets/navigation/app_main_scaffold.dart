import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../buttons/app_fab.dart';
import 'app_bottom_nav_bar.dart';
import 'app_nav_item.dart';

/// The shell every top-level tab screen (Dashboard, Inventory, Billing,
/// Analytics, Settings) is rendered inside — wires up [AppBottomNavBar]
/// and the floating "Start New Sale" [AppFab] consistently so no screen
/// re-implements this composition. See docs/17_FOLDER_STRUCTURE.md and the
/// BOTTOM NAVIGATION design brief.
class AppMainScaffold extends StatelessWidget {
  const AppMainScaffold({
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
    required this.onNewSale,
    super.key,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onNewSale;

  static const items = [
    AppNavItem(
      icon: LucideIcons.layoutGrid,
      activeIcon: LucideIcons.layoutGrid,
      label: 'Dashboard',
    ),
    AppNavItem(
      icon: LucideIcons.package,
      activeIcon: LucideIcons.package,
      label: 'Inventory',
    ),
    AppNavItem(
      icon: LucideIcons.receipt,
      activeIcon: LucideIcons.receipt,
      label: 'Billing',
    ),
    AppNavItem(
      icon: LucideIcons.barChart3,
      activeIcon: LucideIcons.barChart3,
      label: 'Analytics',
    ),
    AppNavItem(
      icon: LucideIcons.settings,
      activeIcon: LucideIcons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: body,
      floatingActionButton: AppFab(onPressed: onNewSale),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}
