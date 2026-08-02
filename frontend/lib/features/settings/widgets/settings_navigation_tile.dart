import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';
import 'settings_tile.dart';

/// A [SettingsTile] that navigates somewhere — trailing chevron, optional
/// [valueLabel] (e.g. a current selection shown inline, like "58mm" or
/// "English") shown just before the chevron.
class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    this.valueLabel,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final String? valueLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      iconBackground: iconBackground,
      enabled: enabled,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valueLabel != null) ...[
            Text(valueLabel!,
                style:
                    AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
            const SizedBox(width: 4),
          ],
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.textGrey),
        ],
      ),
    );
  }
}
