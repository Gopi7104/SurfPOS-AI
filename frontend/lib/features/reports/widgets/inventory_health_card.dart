import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/headers/section_header.dart';
import 'kpi_card.dart';
import 'kpi_grid.dart';

/// Inventory Health — Low Stock/Out of Stock are real, live figures
/// (`ReportsSnapshot.inventoryOverview`, read straight from
/// `InventoryRepository`); Overstock/Dead Stock/Inventory Value/Average
/// Stock Age have no data source anywhere yet, so they render as the same
/// honest "coming soon" [KpiCard] placeholder state as the KPI section
/// above — never an invented count or dollar figure.
class InventoryHealthCard extends StatelessWidget {
  const InventoryHealthCard({
    required this.lowStockCount,
    required this.outOfStockCount,
    super.key,
  });

  final int lowStockCount;
  final int outOfStockCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Inventory Health'),
        KpiGrid(children: [
          KpiCard(
            label: 'Low Stock',
            icon: LucideIcons.triangleAlert,
            value: lowStockCount.toDouble(),
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningContainer,
          ),
          KpiCard(
            label: 'Out of Stock',
            icon: LucideIcons.packageX,
            value: outOfStockCount.toDouble(),
            iconColor: AppColors.error,
            iconBackground: AppColors.errorContainer,
          ),
          const KpiCard(label: 'Overstock', icon: LucideIcons.boxes),
          const KpiCard(label: 'Dead Stock', icon: LucideIcons.packageMinus),
          const KpiCard(label: 'Inventory Value', icon: LucideIcons.wallet),
          const KpiCard(label: 'Avg. Stock Age', icon: LucideIcons.clock),
        ]),
      ],
    );
  }
}
