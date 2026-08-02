import 'package:flutter/material.dart';

import '../../../core/widgets/cards/stat_card.dart';

/// One metric tile — thin wrapper over the shared [StatCard], mirroring
/// `DashboardSummaryStatCard`/Reports' `SummaryCard`. Used both by
/// [CustomerStatsCard] (the Customer Statistics grid) and Customer
/// Details' quick-stats row (Lifetime Spend/Total Orders/Average Order
/// Value).
class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StatCard(label: label, value: value, icon: icon);
  }
}
