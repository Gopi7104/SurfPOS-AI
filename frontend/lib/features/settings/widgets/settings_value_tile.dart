import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import 'settings_tile.dart';

/// A read-only [SettingsTile] with a trailing Copy button — API URL,
/// Merchant ID, Store ID, App Version, and other "Information Settings"
/// all render through this one widget rather than a bespoke row per site.
class SettingsValueTile extends StatelessWidget {
  const SettingsValueTile({
    required this.label,
    this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String? value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: label,
      subtitle: value ?? '—',
      icon: icon,
      iconColor: AppColors.textGrey,
      iconBackground: AppColors.disabledSurface,
      trailing: value == null
          ? null
          : IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(LucideIcons.copy,
                  size: 16, color: AppColors.textGrey),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value!));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied.')),
                );
              },
            ),
    );
  }
}
