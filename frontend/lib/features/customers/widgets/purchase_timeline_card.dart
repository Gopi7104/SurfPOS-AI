import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../models/customer_purchase.dart';
import 'customer_empty_state.dart';

/// Purchase Timeline — a vertical timeline of [CustomerPurchase] rows
/// (receipt number, date, amount, payment method, status), fully built
/// against the real `CustomerPurchase` model exactly like Reports'
/// `SalesTrendCard` is fully built against its real point model. This
/// always renders the empty state today: `CustomerRepositoryImpl
/// .getPurchaseHistory()` always returns `[]` (no persisted Sale/order
/// history exists anywhere in this app yet — see its own header comment),
/// and demo data has no per-customer purchase link either (`DemoSale` has
/// no `customerId`). That's the accurate, honest state — never fabricated.
class PurchaseTimelineCard extends StatelessWidget {
  const PurchaseTimelineCard({
    required this.purchases,
    this.trailing,
    super.key,
  });

  final List<CustomerPurchase> purchases;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Purchase Timeline', trailing: trailing),
        if (purchases.isEmpty)
          const CustomerEmptyState(
            title: 'No purchase history yet',
            message: 'Completed purchases will appear here as a timeline.',
          )
        else
          Column(
            children: [
              for (var i = 0; i < purchases.length; i++)
                _TimelineRow(
                    purchase: purchases[i], isLast: i == purchases.length - 1),
            ],
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.purchase, required this.isLast});

  final CustomerPurchase purchase;
  final bool isLast;

  StatusTone get _tone => switch (purchase.status) {
        PurchaseStatus.completed => StatusTone.success,
        PurchaseStatus.cancelled => StatusTone.neutral,
        PurchaseStatus.refunded => StatusTone.warning,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              if (!isLast)
                const Expanded(
                    child: VerticalDivider(width: 1, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(purchase.receiptNumber,
                            style: AppTypography.bodyMD
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(_formatDate(purchase.date),
                            style: AppTypography.caption),
                        const SizedBox(height: 2),
                        Text(purchase.paymentMethod,
                            style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${purchase.total.toStringAsFixed(2)}',
                          style: AppTypography.bodyMD
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(label: purchase.status.label, tone: _tone),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
