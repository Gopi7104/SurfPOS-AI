import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// The primary call-to-action button — gradient fill, primary-tinted glow
/// shadow, and a tactile press-scale micro-animation. This is the button
/// every "Checkout", "Continue", "Confirm" action in the app should use.
///
/// Custom-painted rather than themed [ElevatedButton] styling so the
/// gradient + glow read correctly (see docs/06_UI_UX_GUIDE.md § 6).
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Fills available width when true (the default — most primary actions
  /// are full-width per the mobile-first checkout/onboarding flows).
  final bool expand;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.curve.standard,
      child: Container(
        height: AppSpacing.minTapTarget + 8,
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: _enabled ? AppColors.primaryGradient : null,
          color: _enabled ? null : AppColors.disabledSurface,
          boxShadow: _enabled ? AppShadows.primaryGlow : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: _labelColor),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            widget.label,
                            style: AppTypography.buttonLG
                                .copyWith(color: _labelColor),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expand ? child : IntrinsicWidth(child: child);
  }

  Color get _labelColor => _enabled ? AppColors.white : AppColors.disabledText;
}
