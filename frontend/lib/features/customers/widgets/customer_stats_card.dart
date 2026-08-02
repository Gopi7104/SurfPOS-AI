import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../models/customer_stats.dart';
import 'customer_summary_card.dart';

/// The Customer Statistics section — Total Customers/New This Month/
/// Active Customers/VIP Customers/Average Spend/Average Orders, as a grid
/// of [CustomerSummaryCard] tiles. The container widget the spec's
/// "CustomerStatsCard" names; each individual tile is [CustomerSummaryCard].
class CustomerStatsCard extends StatelessWidget {
  const CustomerStatsCard({required this.stats, super.key});

  final CustomerStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.3,
      children: [
        CustomerSummaryCard(
          label: 'Total Customers',
          value: '${stats.totalCustomers}',
          icon: LucideIcons.users,
        ),
        CustomerSummaryCard(
          label: 'New This Month',
          value: '${stats.newThisMonth}',
          icon: LucideIcons.userPlus,
        ),
        CustomerSummaryCard(
          label: 'Active Customers',
          value: '${stats.activeCustomers}',
          icon: LucideIcons.userCheck,
        ),
        CustomerSummaryCard(
          label: 'VIP Customers',
          value: '${stats.vipCustomers}',
          icon: LucideIcons.star,
        ),
        CustomerSummaryCard(
          label: 'Average Spend',
          value: '\$${stats.averageSpend.toStringAsFixed(2)}',
          icon: LucideIcons.dollarSign,
        ),
        CustomerSummaryCard(
          label: 'Average Orders',
          value: stats.averageOrders.toStringAsFixed(1),
          icon: LucideIcons.shoppingBag,
        ),
      ],
    );
  }
}
