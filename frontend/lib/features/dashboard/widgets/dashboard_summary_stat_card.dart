import 'package:flutter/material.dart';

import '../../../core/widgets/cards/stat_card.dart';

/// Adapts the shared [StatCard] to the Dashboard's "Today's Business
/// Summary" KPIs. A thin wrapper (not a duplicate of [StatCard]) so this
/// section's icon/label choices live in one place instead of being repeated
/// at each call site in [DashboardPage]. No trend pill — Billing isn't
/// implemented yet, so there's no historical data to compare against
/// (values are always the zero placeholder until then).
class DashboardSummaryStatCard extends StatelessWidget {
  const DashboardSummaryStatCard({
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
