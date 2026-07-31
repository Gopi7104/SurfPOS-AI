import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../../core/widgets/empty_states/empty_state.dart';

/// Placeholder for the Billing tab — Phase 1 builds only the Dashboard and
/// the app shell (see docs/22_DEVELOPMENT_ROADMAP.md); Billing logic is
/// explicitly out of scope until a future phase is approved.
class BillingPlaceholderScreen extends StatelessWidget {
  const BillingPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Billing'),
      body: EmptyState(
        icon: LucideIcons.receipt,
        title: 'Billing',
        message: 'Coming soon — billing will be available in a future update.',
      ),
    );
  }
}
