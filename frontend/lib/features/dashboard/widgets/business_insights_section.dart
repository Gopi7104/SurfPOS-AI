import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../demo_data/models/business_insight.dart';

/// The Business Insights section — one dynamic card per insight ("Revenue
/// up 18% from yesterday", best-selling category, top customer, ...), each
/// a plain [AppCard] with a tinted icon, matching the flat card style
/// every other Dashboard row (Low Stock, Recent Transactions) already
/// uses — Phase UI/UX 3 dropped the colored left-border accent bar this
/// section used to have, which was the one section visually out of step
/// with the rest of the page. Shows up to 4 at a time.
class BusinessInsightsSection extends StatelessWidget {
  const BusinessInsightsSection({required this.insights, super.key});

  final List<BusinessInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final shown = insights.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Business Insights'),
        for (var i = 0; i < shown.length; i++) ...[
          _InsightCard(insight: shown[i]),
          if (i != shown.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

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
