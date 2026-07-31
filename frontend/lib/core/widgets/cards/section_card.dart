import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../headers/section_header.dart';
import 'app_card.dart';

/// The base card any feature's titled section (Dashboard's Merchant
/// Information/Recent Activity/System Status, Inventory's summary cards,
/// etc.) is built from — an [AppCard] with an optional [SectionHeader]
/// baked in, so every section's title styling stays identical without
/// repeating it at each call site. Feature-agnostic — lives in `core/`
/// per docs/07_CODING_RULES.md § 8, imported by any feature that needs it.
class SectionCard extends StatelessWidget {
  const SectionCard(
      {required this.child, this.title, this.trailing, super.key});

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            SectionHeader(title: title!, trailing: trailing),
            const SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}
