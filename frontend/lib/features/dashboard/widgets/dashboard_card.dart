import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/app_card.dart';
import 'section_header.dart';

/// The base card every Dashboard section (Merchant Information, Recent
/// Activity, System Status) is built from — an [AppCard] with an optional
/// [SectionHeader] baked in, so every section's title styling stays
/// identical without repeating it at each call site.
class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.child, this.title, this.trailing, super.key});

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
