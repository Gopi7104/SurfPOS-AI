import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/avatars/app_avatar.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../reports/models/recent_transaction.dart';

/// The Recent Transactions section — banking-app-style rows: a customer
/// avatar, name, time + payment method icon, the amount, a status badge,
/// and a trailing chevron. Reuses Reports' own [RecentTransaction] model
/// (generic, feature-agnostic) so there's no duplicate transaction shape;
/// never touches Reports code.
class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({required this.transactions, super.key});

  final List<RecentTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    final shown = transactions.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Recent Transactions'),
        for (var i = 0; i < shown.length; i++) ...[
          _TransactionRow(transaction: shown[i]),
          if (i != shown.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final RecentTransaction transaction;

  IconData get _paymentIcon => switch (transaction.paymentMethod) {
        'Cash' => LucideIcons.banknote,
        'Card' => LucideIcons.creditCard,
        'Mobile Payment' => LucideIcons.smartphone,
        _ => LucideIcons.flaskConical,
      };

  StatusTone get _tone => switch (transaction.status) {
        TransactionStatus.successful => StatusTone.success,
        TransactionStatus.failed => StatusTone.error,
        TransactionStatus.cancelled => StatusTone.neutral,
      };

  String get _timeLabel {
    final time = transaction.time;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.month}/${time.day} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final name = transaction.customerName ?? 'Walk-in';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          AppAvatar(name: name, size: 40),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_paymentIcon, size: 12, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(_timeLabel,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style:
                    AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              StatusChip(label: transaction.status.label, tone: _tone),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(LucideIcons.chevronRight,
              size: 16, color: AppColors.textGrey),
        ],
      ),
    );
  }
}
