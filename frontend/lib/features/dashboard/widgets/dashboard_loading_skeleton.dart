import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/loading/skeleton_box.dart';
import '../../../core/widgets/loading/skeleton_list.dart';

/// Shimmer stand-in for the whole Dashboard while the initial load is in
/// flight — shaped like the real layout (merchant card, KPI grid, quick
/// actions row) rather than a bare spinner, per the skeleton-loading
/// convention used elsewhere in the app (see `SkeletonList`/`SkeletonStatGrid`).
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(width: 140, height: 16),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 14),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 14),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 14),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 180, height: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonStatGrid(),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 140, height: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonStatGrid(),
      ],
    );
  }
}
