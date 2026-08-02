import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// The app's single floating action button: **Start New Sale**. Gradient
/// fill, glow shadow, pill-shaped, docked/notched into
/// [AppBottomNavBar] via [AppMainScaffold]. See docs/17_FOLDER_STRUCTURE.md
/// (bottom navigation) and the BOTTOM NAVIGATION design brief. A subtle
/// press-scale, matching [AppPrimaryButton]/[AppCard]'s own tactile
/// feedback, rather than a flat Material ripple alone.
class AppFab extends StatefulWidget {
  const AppFab({
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.label = 'New Sale',
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  State<AppFab> createState() => _AppFabState();
}

class _AppFabState extends State<AppFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.curve.standard,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          gradient: AppColors.primaryGradient,
          boxShadow: AppShadows.primaryGlow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: AppColors.white, size: 22),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.label,
                    style:
                        AppTypography.buttonMD.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
