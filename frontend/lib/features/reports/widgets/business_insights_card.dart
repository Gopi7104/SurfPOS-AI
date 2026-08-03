import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../demo_data/models/business_insight.dart';
import 'empty_reports_view.dart';

/// Smart Business Insights — deterministic, not AI: every message here is
/// `DemoBusinessSnapshot.insights` (see its header comment for exactly how
/// each one is derived — a growth comparison, a top category/customer, a
/// fastest mover, a low-stock count), never generated fresh here. Mirrors
/// `dashboard/widgets/business_insights_section.dart`'s exact visual
/// treatment (a plain [AppCard] with a tinted icon, no colored accent
/// border — Phase UI/UX 7 dropped that border on both to match the flat
/// card style the rest of each page already uses), kept as a Reports-local
/// copy for module encapsulation. Shows the brief's literal fallback copy
/// when there's nothing to report.
class BusinessInsightsCard extends StatelessWidget {
  const BusinessInsightsCard({required this.insights, super.key});

  final List<BusinessInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Smart Business Insights'),
          EmptyReportsView(message: 'No business insights available yet.'),
        ],
      );
    }

    final shown = insights.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Smart Business Insights'),
        for (var i = 0; i < shown.length; i++) ...[
          _InsightTile(insight: shown[i]),
          if (i != shown.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final BusinessInsight insight;

  IconData get _icon => switch (insight.kind) {
        InsightKind.growth => LucideIcons.trendingUp,
        InsightKind.category => LucideIcons.flame,
        InsightKind.customer => LucideIcons.star,
        InsightKind.inventory => LucideIcons.zap,
        InsightKind.lowStock => LucideIcons.triangleAlert,
      };

  Color get _accent => switch (insight.kind) {
        InsightKind.growth => AppColors.success,
        InsightKind.lowStock => AppColors.warning,
        InsightKind.category ||
        InsightKind.customer ||
        InsightKind.inventory =>
          AppColors.primary,
      };

  Color get _tint => switch (insight.kind) {
        InsightKind.growth => AppColors.successContainer,
        InsightKind.lowStock => AppColors.warningContainer,
        InsightKind.category ||
        InsightKind.customer ||
        InsightKind.inventory =>
          AppColors.primarySubtle,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _tint, shape: BoxShape.circle),
            child: Icon(_icon, size: 18, color: _accent),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              insight.message,
              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
