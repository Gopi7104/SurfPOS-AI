import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';

/// A dense, non-scrolling grid of equal-sized cards — the shared shell
/// behind every Dashboard grid (Business Snapshot's KPI cards, Quick
/// Actions), so the `GridView.count(shrinkWrap: ..., physics: ..., ...)`
/// boilerplate isn't repeated at each call site.
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    super.key,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}
