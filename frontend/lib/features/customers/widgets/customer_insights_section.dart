import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../models/customer_model.dart';
import '../models/customer_status.dart';

enum _InsightKind { frequentBuyer, highSpending, recentlyJoined, inactive }

class _Insight {
  const _Insight(this.kind, this.message);
  final _InsightKind kind;
  final String message;
}

/// Customer Insights — deterministic, single-record threshold checks over
/// already-real [CustomerModel] fields (`totalOrders`, `lifetimeSpend`,
/// `memberSince`, `status`) — the same "classify an already-real value"
/// pattern `StatusChip`/`StatTrend` color-mapping already use throughout
/// this app, never a new persisted concept or cross-record aggregate.
/// "Growing Customer" from the design brief is deliberately omitted: there
/// is no historical/trend data per customer to honestly compute a growth
/// insight from a single snapshot. Never fabricates — a brand-new customer
/// with zero orders simply earns no insight beyond "Recently Joined".
class CustomerInsightsSection extends StatelessWidget {
  const CustomerInsightsSection({required this.customer, super.key});

  final CustomerModel customer;

  List<_Insight> get _insights {
    final result = <_Insight>[];
    final now = DateTime.now();

    if (customer.status == CustomerStatus.inactive) {
      result.add(const _Insight(
          _InsightKind.inactive, 'This customer is currently inactive.'));
    }
    if (customer.totalOrders >= 3) {
      result.add(_Insight(_InsightKind.frequentBuyer,
          '${customer.fullName} is a frequent buyer with ${customer.totalOrders} orders.'));
    }
    if (customer.lifetimeSpend >= 300) {
      result.add(_Insight(_InsightKind.highSpending,
          'High spending customer — \$${customer.lifetimeSpend.toStringAsFixed(0)} lifetime.'));
    }
    if (now.difference(customer.memberSince).inDays <= 30) {
      result.add(const _Insight(_InsightKind.recentlyJoined,
          'Recently joined within the last 30 days.'));
    }

    return result;
  }

  IconData _icon(_InsightKind kind) => switch (kind) {
        _InsightKind.frequentBuyer => LucideIcons.repeat,
        _InsightKind.highSpending => LucideIcons.trendingUp,
        _InsightKind.recentlyJoined => LucideIcons.sparkles,
        _InsightKind.inactive => LucideIcons.moon,
      };

  Color _accent(_InsightKind kind) => switch (kind) {
        _InsightKind.frequentBuyer ||
        _InsightKind.recentlyJoined =>
          AppColors.primary,
        _InsightKind.highSpending => AppColors.success,
        _InsightKind.inactive => AppColors.warning,
      };

  Color _tint(_InsightKind kind) => switch (kind) {
        _InsightKind.frequentBuyer ||
        _InsightKind.recentlyJoined =>
          AppColors.primarySubtle,
        _InsightKind.highSpending => AppColors.successContainer,
        _InsightKind.inactive => AppColors.warningContainer,
      };

  @override
  Widget build(BuildContext context) {
    final insights = _insights;
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Customer Insights'),
        for (var i = 0; i < insights.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(
                  left: BorderSide(color: _accent(insights[i].kind), width: 3)),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: _tint(insights[i].kind), shape: BoxShape.circle),
                  child: Icon(_icon(insights[i].kind),
                      size: 16, color: _accent(insights[i].kind)),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(insights[i].message,
                      style: AppTypography.bodySM
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (i != insights.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
