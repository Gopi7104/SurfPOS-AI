import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';

/// A large gradient hero header with rounded bottom corners — used atop
/// Dashboard, Profile, and onboarding-style screens instead of a slim
/// [AppTopBar] when the screen needs a "premium hero" feel. Content (a
/// greeting, an avatar row, quick stats) is composed in via [child].
/// See docs/06_UI_UX_GUIDE.md § 6 (gradient headers).
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.xl,
    ),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
