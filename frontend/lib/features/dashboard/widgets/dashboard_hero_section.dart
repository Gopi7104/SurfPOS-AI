import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/avatars/app_avatar.dart';
import '../../../core/widgets/cards/gradient_hero_card.dart';
import '../../../core/widgets/chips/stat_pill.dart';

/// The Dashboard's new visual focus — a single large gradient hero card
/// (replacing the old plain "Good evening" banner + avatar + notification
/// bell + 4 identical white stat cards): merchant/store/date, a small
/// avatar, one large animated KPI (Today's Revenue + growth vs
/// yesterday), and a row of quick-glance pills underneath.
class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({
    required this.merchantName,
    required this.storeName,
    required this.avatarLabel,
    required this.todayRevenue,
    this.revenueGrowth,
    required this.todayOrders,
    required this.averageOrderValue,
    required this.customersCount,
    super.key,
  });

  final String? merchantName;
  final String? storeName;
  final String avatarLabel;
  final double todayRevenue;
  final double? revenueGrowth;
  final int todayOrders;
  final double averageOrderValue;
  final int customersCount;

  String get _dateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final growth = revenueGrowth;
    final subtitleParts = [
      if (storeName?.isNotEmpty == true) storeName!,
      _dateLabel,
    ];

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
                      merchantName?.isNotEmpty == true
                          ? merchantName!
                          : 'Your Business',
                      style: AppTypography.headingSM
                          .copyWith(color: AppColors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: AppTypography.bodySM.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppAvatar(
                name: avatarLabel,
                size: 36,
                background: AppColors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Today's Revenue",
            style: AppTypography.caption
                .copyWith(color: AppColors.white.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUpNumber(
                value: todayRevenue,
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
          if (growth != null) ...[
            const SizedBox(height: 2),
            Text('vs yesterday',
                style: AppTypography.caption
                    .copyWith(color: AppColors.white.withValues(alpha: 0.6))),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatPill(value: '$todayOrders', label: 'Orders', light: true),
              StatPill(
                  value: '\$${averageOrderValue.toStringAsFixed(0)}',
                  label: 'Avg Order',
                  light: true),
              StatPill(
                  value: '$customersCount', label: 'Customers', light: true),
            ],
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
