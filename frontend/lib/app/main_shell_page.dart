import 'package:flutter/material.dart';

import '../core/widgets/navigation/app_main_scaffold.dart';
import '../features/billing/pages/billing_page.dart';
import '../features/customers/pages/customer_list_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/inventory/pages/inventory_home_page.dart';
import '../features/reports/pages/reports_home_page.dart';
import '../features/settings/pages/settings_home_page.dart';

/// The application shell — the post-login/post-approval destination. Owns
/// which of the 6 tabs (Dashboard/Billing/Inventory/Reports/Customers/
/// Settings) is active and renders all 6 inside an [IndexedStack] so
/// switching tabs never rebuilds/loses the state of the ones not
/// currently visible (e.g. the Dashboard's scroll position and loaded
/// data survive a trip to another tab and back). See
/// docs/22_DEVELOPMENT_ROADMAP.md Phase 1 (BOTTOM NAVIGATION); "Customers"
/// was added in Phase 6.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  // Owned here (not inside DashboardPage) so the floating "New Sale" FAB —
  // a sibling of `body` docked by AppMainScaffold, painted on top of
  // whichever tab is showing — can drive Dashboard's own scroll position
  // when a drag starts on the FAB itself instead of on the list beneath
  // it. See `AppFab.onVerticalDrag`'s header comment for why Flutter's
  // hit-testing otherwise drops that gesture entirely.
  final ScrollController _dashboardScrollController = ScrollController();

  void _goToTab(int index) => setState(() => _currentIndex = index);

  void _handleFabVerticalDrag(double dy) {
    if (_currentIndex != 0 || !_dashboardScrollController.hasClients) return;
    final position = _dashboardScrollController.position;
    _dashboardScrollController.jumpTo(
      (position.pixels - dy)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  void dispose() {
    _dashboardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      currentIndex: _currentIndex,
      onNavTap: _goToTab,
      onNewSale: () => _goToTab(
          1), // Billing tab — "New Bill"/"Start New Sale" both land there.
      onFabVerticalDrag: _handleFabVerticalDrag,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPage(
              onNavigateToTab: _goToTab,
              scrollController: _dashboardScrollController),
          const BillingPage(),
          const InventoryHomePage(),
          const ReportsHomePage(),
          const CustomerListPage(),
          const SettingsHomePage(),
        ],
      ),
    );
  }
}
