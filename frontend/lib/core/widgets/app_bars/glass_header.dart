import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../avatars/app_avatar.dart';
import 'app_gradient_header.dart';

/// The "greeting + identity + trailing actions" hero row — composes
/// [AppGradientHeader] (the shared gradient shell every hero header in
/// this app already uses) with an [AppAvatar], a title/subtitle pair, and
/// an optional trailing action (notification bell, ...), so that specific
/// layout isn't hand-assembled at each call site. Not a second gradient
/// shell — [AppGradientHeader] still owns the surface itself.
class GlassHeader extends StatelessWidget {
  const GlassHeader({
    required this.title,
    required this.subtitle,
    this.avatarLabel,
    this.onAvatarTap,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? avatarLabel;
  final VoidCallback? onAvatarTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppGradientHeader(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (avatarLabel != null) ...[
            GestureDetector(
              onTap: onAvatarTap,
              child: AppAvatar(
                name: avatarLabel!,
                size: 44,
                background: AppColors.white.withValues(alpha: 0.22),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppTypography.headingMD.copyWith(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySM
                      .copyWith(color: AppColors.white.withValues(alpha: 0.82)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
