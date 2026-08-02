import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/empty_states/empty_state.dart';

/// Customers' own preset of the shared [EmptyState] — same consistent
/// icon across every empty spot in this module (no customers yet, no
/// search results, no purchase history), with only the copy/action
/// varying per call site. Not a new empty-state implementation —
/// [EmptyState] still does all the actual rendering.
class CustomerEmptyState extends StatelessWidget {
  const CustomerEmptyState({
    required this.title,
    required this.message,
    this.icon = LucideIcons.users,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
