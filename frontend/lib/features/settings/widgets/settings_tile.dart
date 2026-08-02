import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// The base row every Settings tile (switch, navigation, info) is built
/// from — leading icon in a tinted circle, title/subtitle, and a trailing
/// slot. Not `AppCard`-wrapped itself — [SettingsSection] supplies the
/// surrounding card so a section's rows sit flush together with plain
/// dividers between them, matching Shopify/Square's dense settings-list
/// look rather than one card per row.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled ? AppColors.textDark : AppColors.disabledText;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: enabled ? iconBackground : AppColors.disabledSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon,
                    size: 16,
                    color: enabled ? iconColor : AppColors.disabledText),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodyMD.copyWith(
                          fontWeight: FontWeight.w600, color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTypography.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
