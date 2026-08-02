import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/cards/bento_metric_card.dart';

/// The Metrics section — a 2-column "bento" layout instead of four
/// identical cards: Today's Sales gets a large-emphasis featured card on
/// the left; Orders/Average Order/Customers stack as three smaller cards
/// on the right. Each side sizes to its own natural content height (no
/// forced/equal-height stretching) — a deliberately asymmetric, "different
/// heights" bento rather than a rigid grid.
class BusinessMetricsBento extends StatelessWidget {
  const BusinessMetricsBento({
    required this.todaySales,
    required this.todayOrders,
    required this.averageOrderValue,
    required this.customersCount,
    super.key,
  });

  final double todaySales;
  final int todayOrders;
  final double averageOrderValue;
  final int customersCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BentoMetricCard(
            label: "Today's Sales",
            value: '\$${todaySales.toStringAsFixed(0)}',
            numericValue: todaySales,
            formatter: (v) => '\$${v.toStringAsFixed(0)}',
            icon: LucideIcons.dollarSign,
            featured: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BentoMetricCard(
                label: "Today's Orders",
                value: '$todayOrders',
                numericValue: todayOrders.toDouble(),
                formatter: (v) => v.round().toString(),
                icon: LucideIcons.shoppingBag,
                iconColor: AppColors.success,
                iconBackground: AppColors.successContainer,
              ),
              const SizedBox(height: AppSpacing.sm),
              BentoMetricCard(
                label: 'Average Order',
                value: '\$${averageOrderValue.toStringAsFixed(0)}',
                numericValue: averageOrderValue,
                formatter: (v) => '\$${v.toStringAsFixed(0)}',
                icon: LucideIcons.receipt,
                iconColor: AppColors.warning,
                iconBackground: AppColors.warningContainer,
              ),
              const SizedBox(height: AppSpacing.sm),
              BentoMetricCard(
                label: 'Customers',
                value: '$customersCount',
                numericValue: customersCount.toDouble(),
                formatter: (v) => v.round().toString(),
                icon: LucideIcons.users,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
