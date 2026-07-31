import 'package:flutter/material.dart';

import '../core/widgets/navigation/app_main_scaffold.dart';
import '../features/analytics/presentation/screens/reports_placeholder_screen.dart';
import '../features/billing/pages/billing_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/inventory/pages/inventory_home_page.dart';
import '../features/settings/presentation/screens/settings_placeholder_screen.dart';

/// The application shell — the post-login/post-approval destination. Owns
/// which of the 5 tabs (Dashboard/Billing/Inventory/Reports/Settings) is
/// active and renders all 5 inside an [IndexedStack] so switching tabs
/// never rebuilds/loses the state of the ones not currently visible (e.g.
/// the Dashboard's scroll position and loaded data survive a trip to
/// another tab and back). See docs/22_DEVELOPMENT_ROADMAP.md Phase 1
/// (BOTTOM NAVIGATION).
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      currentIndex: _currentIndex,
      onNavTap: _goToTab,
      onNewSale: () => _goToTab(
          1), // Billing tab — "New Bill"/"Start New Sale" both land there.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPage(onNavigateToTab: _goToTab),
          const BillingPage(),
          const InventoryHomePage(),
          const ReportsPlaceholderScreen(),
          const SettingsPlaceholderScreen(),
        ],
      ),
    );
  }
}
