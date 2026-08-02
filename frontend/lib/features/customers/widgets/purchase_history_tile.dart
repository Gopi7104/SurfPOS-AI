import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/customer_purchase.dart';

/// One row in a customer's Purchase History — receipt number, date,
/// items, total, payment method, and status.
class PurchaseHistoryTile extends StatelessWidget {
  const PurchaseHistoryTile({required this.purchase, super.key});

  final CustomerPurchase purchase;

  StatusTone get _tone => switch (purchase.status) {
        PurchaseStatus.completed => StatusTone.success,
        PurchaseStatus.cancelled => StatusTone.neutral,
        PurchaseStatus.refunded => StatusTone.warning,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                Text(_formatDate(purchase.date), style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  purchase.items.isEmpty ? '—' : purchase.items.join(', '),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(purchase.paymentMethod, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
