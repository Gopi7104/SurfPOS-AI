import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../models/billing_state.dart';

/// The Order Summary — Subtotal/Tax/Discount/Grand Total, recomputed from
/// [state] on every rebuild (see `BillingState`'s getters). Deliberately
/// shows only fields the order model actually carries — no invented "Service
/// Fee" or similar line. Purely presentational; Clear Cart/Proceed to
/// Payment live in `CartBottomSheet`, the only place this card is used.
class BillingSummaryCard extends StatelessWidget {
  const BillingSummaryCard({required this.state, super.key});

  final BillingState state;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order Summary', style: AppTypography.headingSM),
          const SizedBox(height: AppSpacing.sm),
          _TotalRow(label: 'Subtotal', value: state.subtotal),
          _TotalRow(label: 'Tax', value: state.taxTotal),
          _TotalRow(label: 'Discount', value: -state.discountTotal),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _TotalRow(
              label: 'Grand Total', value: state.grandTotal, emphasize: true),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(
      {required this.label, required this.value, this.emphasize = false});

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? AppTypography.bodyLG.copyWith(fontWeight: FontWeight.w800)
        : AppTypography.bodyMD.copyWith(color: AppColors.textGrey);
    final valueStyle = emphasize
        ? AppTypography.headingSM.copyWith(color: AppColors.primary)
        : AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: valueStyle),
        ],
      ),
    );
  }
}
