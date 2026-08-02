import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/recent_transaction.dart';

/// One row in the Recent Transactions list — receipt number, customer,
/// amount, status, payment method, and time.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final RecentTransaction transaction;

  StatusTone get _tone => switch (transaction.status) {
        TransactionStatus.successful => StatusTone.success,
        TransactionStatus.failed => StatusTone.error,
        TransactionStatus.cancelled => StatusTone.neutral,
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
                Text(transaction.receiptNumber,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(transaction.customerName ?? 'Walk-in',
                    style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  '${transaction.paymentMethod} • ${_formatTime(transaction.time)}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              StatusChip(label: transaction.status.label, tone: _tone),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
