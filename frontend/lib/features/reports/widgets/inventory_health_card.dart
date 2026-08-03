import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/headers/section_header.dart';
import 'kpi_card.dart';
import 'kpi_grid.dart';

/// Inventory Health — Low Stock/Out of Stock, real live figures
/// (`ReportsSnapshot.inventoryOverview`, read straight from
/// `InventoryRepository`). Used to also show Overstock/Dead Stock/
/// Inventory Value/Average Stock Age as permanent "coming soon" [KpiCard]
/// placeholders — removed in Phase UI/UX 7 along with this page's other
/// never-real placeholder sections (see `ReportsHomePage`'s header
/// comment) since none of the four ever had a data source to back them.
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
        ]),
      ],
    );
  }
}
