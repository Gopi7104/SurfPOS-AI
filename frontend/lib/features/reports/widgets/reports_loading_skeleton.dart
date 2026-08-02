import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/loading/skeleton_box.dart';
import '../../../core/widgets/loading/skeleton_list.dart';

/// Shimmer stand-in for the whole Reports Home screen while the initial
/// load is in flight — shaped like the real layout (KPI grids, a chart
/// block, a list block) rather than a bare spinner, same skeleton-loading
/// convention as [DashboardLoadingSkeleton].
class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        SkeletonBox(width: 160, height: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonStatGrid(itemCount: 4),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 120, height: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonStatGrid(itemCount: 4),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 140, height: 16),
        SizedBox(height: AppSpacing.sm),
        AppCard(
          child: SizedBox(height: 180, child: SkeletonBox(height: 180)),
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 180, height: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonList(itemCount: 3, shrinkWrap: true),
      ],
    );
  }
}
