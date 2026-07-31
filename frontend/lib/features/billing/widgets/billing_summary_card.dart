import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../models/billing_state.dart';

/// Subtotal/Tax/Discount/Grand Total breakdown plus the Clear Cart and
/// Checkout actions — purely presentational, recomputed from [state] on
/// every rebuild (see `BillingState`'s getters), never computes totals
/// itself.
class BillingSummaryCard extends StatelessWidget {
  const BillingSummaryCard({
    required this.state,
    required this.onClearCart,
    required this.onCheckout,
    super.key,
  });

  final BillingState state;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalRow(label: 'Subtotal', value: state.subtotal),
          _TotalRow(label: 'Tax', value: state.taxTotal),
          _TotalRow(label: 'Discount', value: -state.discountTotal),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _TotalRow(
              label: 'Grand Total', value: state.grandTotal, emphasize: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isEmpty ? null : onClearCart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Clear Cart'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: 'Checkout',
                  onPressed: state.isEmpty ? null : onCheckout,
                ),
              ),
            ],
          ),
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
