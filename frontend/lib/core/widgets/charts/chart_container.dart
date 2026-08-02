import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../cards/app_card.dart';
import '../headers/section_header.dart';

/// The generic shell every chart section (Revenue, Sales Trend, Payment
/// Breakdown, ...) is built from — title (+ optional trailing control, e.g.
/// a period toggle), a fixed-height plot area, wrapped in a
/// [RepaintBoundary] so a chart's own repaints (touch/tooltip, animation)
/// never bleed into sibling sections. Mirrors Reports' own `ChartCard`
/// shell but generic — takes any [child], not just a line-chart-of-points
/// — so Dashboard's charts don't duplicate that Reports-specific widget.
class ChartContainer extends StatelessWidget {
  const ChartContainer({
    required this.title,
    required this.child,
    this.trailing,
    this.height = 220,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, trailing: trailing),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: height,
            child: RepaintBoundary(child: child),
          ),
        ],
      ),
    );
  }
}
