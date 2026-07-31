import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../../core/widgets/empty_states/empty_state.dart';

/// Placeholder for the Inventory tab — Phase 1 builds only the Dashboard and
/// the app shell (see docs/22_DEVELOPMENT_ROADMAP.md); Inventory logic is
/// explicitly out of scope until a future phase is approved.
class InventoryPlaceholderScreen extends StatelessWidget {
  const InventoryPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Inventory'),
      body: EmptyState(
        icon: LucideIcons.package,
        title: 'Inventory',
        message: 'Coming soon — inventory management will be available in a future update.',
      ),
    );
  }
}
