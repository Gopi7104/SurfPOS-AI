import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/progress/app_progress_bar.dart';

/// Category Performance — always a placeholder today. Neither the real
/// `ReportsSnapshot.categoryBreakdown` (revenue-by-category only, no
/// units/contribution breakdown) nor `DemoBusinessSnapshot` exposes a
/// {category, revenue, units, contribution%} aggregate, so this section
/// has no honest data to show — see the Reports redesign deliverable notes
/// for what a future `ReportsRepository`/`DemoBusinessSnapshot` addition
/// would need to back it. Kept visually "designed" (a dimmed bar mockup)
/// rather than a bare empty box, without ever presenting the dimmed rows
/// as real numbers.
class CategoryPerformanceCard extends StatelessWidget {
  const CategoryPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartContainer(
      title: 'Category Performance',
      height: 168,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final width in [0.7, 0.5, 0.32]) ...[
            Opacity(
              opacity: 0.35,
              child: AppProgressBar(value: width, color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            'Category performance is coming soon.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
