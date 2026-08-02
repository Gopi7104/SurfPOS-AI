import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/section_card.dart';

/// Thin wrapper over the shared [SectionCard] — the base surface every
/// Settings section/sub-block is built from, mirroring how Reports'
/// `SummaryCard`/Customers' `CustomerSummaryCard` each wrap a core widget
/// rather than reimplementing a card. Uses a tighter padding than
/// [SectionCard]'s app-wide default so a dense list of compact rows
/// doesn't carry a full card's worth of whitespace around it.
class SettingsCard extends StatelessWidget {
  const SettingsCard(
      {required this.child, this.title, this.trailing, super.key});

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: trailing,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: child,
    );
  }
}
