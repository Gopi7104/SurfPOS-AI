import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/avatars/app_avatar.dart';
import '../../../core/widgets/cards/gradient_hero_card.dart';

enum _HeroPeriod { today, week, month, year }

/// Reports' new hero — one large gradient card replacing the old plain
/// "Reports" [AppGradientHeader] title bar. Shows a time-of-day greeting,
/// the merchant's name/avatar, and one large animated revenue figure with
/// a Today/Week/Month/Year pill toggle underneath.
///
/// The toggle is purely local UI state — it only decides which of the
/// already-computed `SalesSummary`/`DemoBusinessSnapshot` figures passed in
/// via the `*Sales`/`*Growth` params is shown, exactly the same "local
/// toggle over already-fetched data" pattern
/// `dashboard/widgets/revenue_chart_section.dart`'s own Today/Week/Month
/// toggle uses. It never touches [ReportsController]/[ReportFilterBar] —
/// that filter still independently drives every other section on the page
/// exactly as before.
class AnalyticsHeroHeader extends StatefulWidget {
  const AnalyticsHeroHeader({
    required this.merchantName,
    required this.avatarLabel,
    required this.todaySales,
    this.todaySalesGrowth,
    required this.thisWeekSales,
    this.thisWeekGrowth,
    required this.thisMonthSales,
    this.thisMonthGrowth,
    required this.totalRevenue,
    this.totalRevenueGrowth,
    super.key,
  });

  final String? merchantName;
  final String avatarLabel;
  final double todaySales;
  final double? todaySalesGrowth;
  final double thisWeekSales;
  final double? thisWeekGrowth;
  final double thisMonthSales;
  final double? thisMonthGrowth;

  /// All-time total — stands in for "Year" (`SalesSummary`/
  /// `DemoBusinessSnapshot` have no separate this-year figure; see
  /// `ReportsSnapshot`'s header comment on which windows exist today).
  final double totalRevenue;
  final double? totalRevenueGrowth;

  @override
  State<AnalyticsHeroHeader> createState() => _AnalyticsHeroHeaderState();
}

class _AnalyticsHeroHeaderState extends State<AnalyticsHeroHeader> {
  _HeroPeriod _period = _HeroPeriod.today;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  (double amount, double? growth, String label) get _selected =>
      switch (_period) {
        _HeroPeriod.today => (
            widget.todaySales,
            widget.todaySalesGrowth,
            "Today's Revenue"
          ),
        _HeroPeriod.week => (
            widget.thisWeekSales,
            widget.thisWeekGrowth,
            "This Week's Revenue"
          ),
        _HeroPeriod.month => (
            widget.thisMonthSales,
            widget.thisMonthGrowth,
            "This Month's Revenue"
          ),
        _HeroPeriod.year => (
            widget.totalRevenue,
            widget.totalRevenueGrowth,
            'Total Revenue'
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (amount, growth, label) = _selected;

    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: AppTypography.bodySM.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.merchantName?.isNotEmpty == true
                          ? widget.merchantName!
                          : 'Your Business',
                      style: AppTypography.headingSM
                          .copyWith(color: AppColors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Business Overview',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppAvatar(
                name: widget.avatarLabel,
                size: 40,
                background: AppColors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.white.withValues(alpha: 0.78))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUpNumber(
                value: amount,
                formatter: (v) => '\$${v.toStringAsFixed(0)}',
                style: AppTypography.numberXL.copyWith(color: AppColors.white),
              ),
              if (growth != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _GrowthBadge(growth: growth),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PeriodPillRow(
            period: _period,
            onChanged: (period) => setState(() => _period = period),
          ),
        ],
      ),
    );
  }
}

class _GrowthBadge extends StatelessWidget {
  const _GrowthBadge({required this.growth});

  final double growth;

  @override
  Widget build(BuildContext context) {
    final isUp = growth >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '${growth.abs().toStringAsFixed(0)}%',
            style: AppTypography.caption
                .copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PeriodPillRow extends StatelessWidget {
  const _PeriodPillRow({required this.period, required this.onChanged});

  final _HeroPeriod period;
  final ValueChanged<_HeroPeriod> onChanged;

  String _label(_HeroPeriod p) => switch (p) {
        _HeroPeriod.today => 'Today',
        _HeroPeriod.week => 'Week',
        _HeroPeriod.month => 'Month',
        _HeroPeriod.year => 'Year',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _HeroPeriod.values)
            GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: option == period ? AppColors.white : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _label(option),
                  style: AppTypography.caption.copyWith(
                    color:
                        option == period ? AppColors.primary : AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
