import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';

/// A responsive grid for [KpiCard] tiles — 2 columns on a phone portrait,
/// 3 on a wider phone/small tablet, 4 on a tablet/landscape, so the KPI
/// section adapts instead of a fixed `crossAxisCount`.
class KpiGrid extends StatelessWidget {
  const KpiGrid({required this.children, super.key});

  final List<Widget> children;

  int _columnsFor(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.05,
          children: children,
        );
      },
    );
  }
}
