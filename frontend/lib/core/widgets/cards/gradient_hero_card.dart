import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';

/// A large, fully-rounded gradient card — the "hero" surface for a
/// screen's single most important figure (Dashboard's Today's Revenue,
/// and reusable anywhere else a similar hero KPI is needed later). Purely
/// a surface: callers compose their own content (title row, big number,
/// pills, ...) via [child], the same way [AppCard]/[ChartContainer] only
/// provide a shell. Distinct from [AppGradientHeader] — that one is a
/// full-bleed, rounded-bottom-only top banner; this is a self-contained
/// card that sits inline in scrollable content with margin around it.
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: child,
    );
  }
}
