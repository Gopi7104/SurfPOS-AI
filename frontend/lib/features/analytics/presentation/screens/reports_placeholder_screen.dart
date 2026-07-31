import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../../core/widgets/empty_states/empty_state.dart';

/// Placeholder for the Reports tab (the app's Analytics feature module —
/// see `features/analytics/README.md`). Phase 1 builds only the Dashboard
/// and the app shell (see docs/22_DEVELOPMENT_ROADMAP.md); Reports logic is
/// explicitly out of scope until a future phase is approved.
class ReportsPlaceholderScreen extends StatelessWidget {
  const ReportsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Reports'),
      body: EmptyState(
        icon: LucideIcons.barChart3,
        title: 'Reports',
        message: 'Coming soon — sales and inventory reports will be available in a future update.',
      ),
    );
  }
}
