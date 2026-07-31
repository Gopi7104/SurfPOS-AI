import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../billing/models/billing_state.dart';

/// Shown before a checkout attempt is created — a last confirmation of
/// merchant/store/products/totals before this app talks to Surfboard at all.
/// Purely presentational: the actual checkout call only happens after
/// [onConfirm] is invoked (see `BillingPage._openCheckout`).
class PaymentSummaryDialog extends StatelessWidget {
  const PaymentSummaryDialog({
    required this.cart,
    required this.merchantName,
    required this.storeName,
    required this.onConfirm,
    super.key,
  });

  final BillingState cart;
  final String merchantName;
  final String storeName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Summary'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoRow(label: 'Merchant', value: merchantName),
              _InfoRow(label: 'Store', value: storeName),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Text('Products',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              for (final item in cart.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} × ${item.quantity}',
                          style: AppTypography.bodyMD,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('\$${item.lineTotal.toStringAsFixed(2)}',
                          style: AppTypography.bodyMD),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _TotalRow(label: 'Subtotal', value: cart.subtotal),
              _TotalRow(label: 'Tax', value: cart.taxTotal),
              _TotalRow(label: 'Discount', value: -cart.discountTotal),
              _TotalRow(label: 'Grand Total', value: cart.grandTotal),
              const SizedBox(height: AppSpacing.xs),
              // Equal to Grand Total in this phase (no tips/split payments yet) — shown as
              // its own line per the Payment Summary spec, since a future phase could make
              // the two diverge.
              _TotalRow(
                  label: 'Payment Amount',
                  value: cart.grandTotal,
                  emphasize: true),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        AppPrimaryButton(
          label: 'Confirm',
          expand: false,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
          Text(value,
              style:
                  AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600)),
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
        ? AppTypography.bodyLG
            .copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)
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
