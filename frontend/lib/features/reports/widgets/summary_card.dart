import 'package:flutter/material.dart';

import '../../../core/widgets/cards/stat_card.dart';

/// Adapts the shared [StatCard] to a Reports KPI — amount, growth %, and a
/// trend icon, exactly the Sales Summary/Orders spec's "Amount / Growth % /
/// Small trend icon" shape. A thin wrapper (not a duplicate of [StatCard]),
/// mirroring `DashboardSummaryStatCard`'s own pattern — the only thing this
/// adds is mapping a nullable growth percent onto [StatCard]'s
/// `trendLabel`/`trend`.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.growthPercent,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Percent change vs. the prior equivalent window — `null` when there is
  /// no prior window to compare against yet, in which case no trend pill
  /// is shown at all (never a fabricated "0%").
  final double? growthPercent;

  @override
  Widget build(BuildContext context) {
    final growth = growthPercent;
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      trendLabel: growth == null ? null : '${growth.abs().toStringAsFixed(1)}%',
      trend: growth == null
          ? StatTrend.flat
          : (growth >= 0 ? StatTrend.up : StatTrend.down),
    );
  }
}
