import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/empty_states/empty_state.dart';

/// Reports' own preset of the shared [EmptyState] — same consistent
/// icon/title across every section (Sales Chart, Top Products, Category
/// Breakdown, Recent Transactions) that has nothing to show yet, with only
/// the [message] varying per section. Not a new empty-state implementation
/// — [EmptyState] still does all the actual rendering.
class EmptyReportsView extends StatelessWidget {
  const EmptyReportsView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.barChart3,
      title: 'Nothing to show yet',
      message: message,
    );
  }
}
