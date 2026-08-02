import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../buttons/app_fab.dart';
import 'app_bottom_nav_bar.dart';
import 'app_nav_item.dart';

/// The shell every top-level tab screen (Dashboard, Billing, Inventory,
/// Reports, Customers, Settings) is rendered inside — wires up
/// [AppBottomNavBar] consistently so no screen re-implements that
/// composition. See docs/17_FOLDER_STRUCTURE.md and the BOTTOM NAVIGATION
/// design brief. "Customers" (Phase 6) was added after Reports — the FAB
/// floats independently (`centerFloat`, no Material notch), so a 6th
/// destination doesn't disturb its position, just narrows each nav item
/// slightly.
///
/// The floating "Start New Sale" [AppFab] is shown only on the Dashboard
/// tab (index 0 in [items]) — it's the one screen where starting a sale is
/// the primary action. Every other tab renders `floatingActionButton: null`
/// here: Billing is already mid-sale (its own "Proceed to Payment" bar
/// covers that), Reports/Customers/Settings have no sale-starting action at
/// all, and Inventory has its own, differently-purposed "Add Product" FAB
/// (`InventoryHomePage`'s own `Scaffold.floatingActionButton`) — before this
/// change that inner FAB was rendered directly underneath this shell's
/// global one, at nearly the same screen position, on every tab.
class AppMainScaffold extends StatelessWidget {
  const AppMainScaffold({
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
    required this.onNewSale,
    this.onFabVerticalDrag,
    super.key,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onNewSale;

  /// See [AppFab.onVerticalDrag] — lets the active tab keep scrolling when
  /// a drag starts on the floating "New Sale" button instead of on its own
  /// content. `null` (the default) leaves every tab's FAB behavior exactly
  /// as before.
  final ValueChanged<double>? onFabVerticalDrag;

  /// Order matches the Merchant Dashboard build brief exactly — index 0..4
  /// is Dashboard/Billing/Inventory/Reports/Settings; see
  /// `DashboardTabTargets` in `features/dashboard/pages/dashboard_page.dart`
  /// for the indices Quick Actions navigate to.
  static const items = [
    AppNavItem(
      icon: LucideIcons.layoutGrid,
      activeIcon: LucideIcons.layoutGrid,
      label: 'Dashboard',
    ),
    AppNavItem(
      icon: LucideIcons.receipt,
      activeIcon: LucideIcons.receipt,
      label: 'Billing',
    ),
    AppNavItem(
      icon: LucideIcons.package,
      activeIcon: LucideIcons.package,
      label: 'Inventory',
    ),
    AppNavItem(
      icon: LucideIcons.barChart3,
      activeIcon: LucideIcons.barChart3,
      label: 'Reports',
    ),
    AppNavItem(
      icon: LucideIcons.users,
      activeIcon: LucideIcons.users,
      label: 'Customers',
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
      floatingActionButton: currentIndex == 0
          ? AppFab(onPressed: onNewSale, onVerticalDrag: onFabVerticalDrag)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}
