import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import 'settings_card.dart';

/// One of the 13 Settings Home sections (Business, POS, Printer, ...) —
/// an icon+title header (via [SettingsCard]/`SectionHeader`) over a
/// column of [SettingsTile]/[SettingsSwitchTile]/[SettingsNavigationTile]/
/// [SettingsInfoTile] rows, each separated by a plain divider so a
/// section reads as one dense list rather than a stack of separate cards
/// — the Shopify/Square POS settings look the brief calls for.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: title,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}
