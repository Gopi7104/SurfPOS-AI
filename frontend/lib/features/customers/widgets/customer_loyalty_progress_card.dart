import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../models/customer_model.dart';
import '../models/customer_purchase.dart';
import '../models/loyalty.dart';

/// Reward Progress + Points History (Phase CRM-1) — additive alongside
/// `CustomerLoyaltyCard` rather than folded into it, so that widget's own
/// "Points/Tier/Coupons/Rewards/Referral" layout stays untouched. Both
/// derived from real data already computed elsewhere: progress toward the
/// next tier via [nextTierProgress] (the same thresholds
/// `CustomerModel.membershipTier` uses), and points history by re-applying
/// the same [pointsEarnedForAmount] rule `CustomerRepositoryImpl.
/// recordPurchase` used at the time of each purchase.
class CustomerLoyaltyProgressCard extends StatelessWidget {
  const CustomerLoyaltyProgressCard({
    required this.customer,
    required this.recentPurchases,
    super.key,
  });

  final CustomerModel customer;
  final List<CustomerPurchase> recentPurchases;

  @override
  Widget build(BuildContext context) {
    final progress = nextTierProgress(customer.lifetimePoints);

    return SectionCard(
      title: 'Reward Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress == null)
            Row(
              children: [
                const Icon(LucideIcons.gem, size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Highest tier reached — Diamond.',
                    style: AppTypography.bodySM
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              '${progress.pointsToGo} points to ${progress.tier.label}',
              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
          if (recentPurchases.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Points History',
                style: AppTypography.bodySM.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.textGrey)),
            const SizedBox(height: AppSpacing.sm),
            for (final purchase in recentPurchases.take(5)) ...[
              _PointsHistoryRow(purchase: purchase),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}

class _PointsHistoryRow extends StatelessWidget {
  const _PointsHistoryRow({required this.purchase});

  final CustomerPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final points = pointsEarnedForAmount(purchase.total);
    return Row(
      children: [
        const Icon(LucideIcons.plus, size: 14, color: AppColors.success),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$points points from order ${purchase.receiptNumber}',
            style: AppTypography.bodySM,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(_formatDate(purchase.date), style: AppTypography.caption),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
