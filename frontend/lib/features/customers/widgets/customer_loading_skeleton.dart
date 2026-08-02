import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/loading/skeleton_list.dart';

/// Shimmer stand-in for the Customer List while the initial load is in
/// flight — same skeleton-loading convention as
/// `DashboardLoadingSkeleton`/`ReportsLoadingSkeleton`, reusing the shared
/// [SkeletonList] rather than a new row shimmer implementation.
class CustomerLoadingSkeleton extends StatelessWidget {
  const CustomerLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SkeletonList(itemCount: 8),
    );
  }
}
