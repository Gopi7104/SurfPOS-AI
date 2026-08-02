import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../demo_data/models/business_insight.dart';

/// The Business Insights section — one dynamic card per insight ("Revenue
/// up 18% from yesterday", best-selling category, top customer, ...),
/// each with a tinted icon and a colored accent bar rather than a plain
/// chip, so they read as genuine cards. Shows 2–4 at a time.
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: _accent, width: 3)),
        boxShadow: AppShadows.card,
      ),
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
