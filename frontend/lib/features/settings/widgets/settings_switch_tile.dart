import 'package:flutter/material.dart';

import 'settings_tile.dart';

/// A [SettingsTile] with a trailing [Switch] — every boolean preference
/// across every section (Auto Print Receipt, Loyalty Enabled, Low Stock
/// Alerts, ...) is this one widget with different labels/values.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
