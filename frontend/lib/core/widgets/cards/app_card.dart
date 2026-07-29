import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';

/// The base surface every card in the app is built from — white surface,
/// large soft-shadow elevation, rounded corners. Optional [onTap] adds a
/// subtle press-scale micro-animation instead of a flat Material ripple,
/// matching the "modern cards" brief. See docs/06_UI_UX_GUIDE.md § 6.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surface,
    this.border,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BoxBorder? border;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve.standard,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: widget.border,
        boxShadow: _pressed ? AppShadows.subtle : AppShadows.card,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return content;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve.standard,
        child: content,
      ),
    );
  }
}
