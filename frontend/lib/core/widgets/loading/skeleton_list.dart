import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../cards/app_card.dart';
import 'skeleton_box.dart';

/// A skeleton stand-in for a list of rows (e.g. products, sales history)
/// while real data loads. See docs/06_UI_UX_GUIDE.md § 7.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.itemCount = 6, this.shrinkWrap = false, super.key});

  final int itemCount;

  /// Set to `true` when embedding this inside another scrollable (e.g.
  /// [ReportsLoadingSkeleton]'s outer `ListView`) — sizes to content and
  /// disables its own scrolling instead of demanding unbounded height.
  /// Leave `false` (default) when this is the sole scrollable body, where
  /// it should fill and scroll the available space itself.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          SkeletonBox(width: 44, height: 44, radius: AppRadius.sm),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 48, height: 20),
        ],
      ),
    );
  }
}

/// A skeleton stand-in for the Dashboard stat-card grid.
class SkeletonStatGrid extends StatelessWidget {
  const SkeletonStatGrid({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (_, __) => const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 40, height: 40, radius: AppRadius.sm),
            SkeletonBox(width: 70, height: 22),
            SkeletonBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}
