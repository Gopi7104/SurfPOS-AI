import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../billing/models/billing_state.dart';
import '../../billing/models/customer_details.dart';

/// Shown before a checkout attempt is created — a last confirmation of
/// merchant/store/products/totals/customer plus a choice of payment method,
/// before this app talks to Surfboard (or, for the dev-only Test Payment
/// card, before it simulates a checkout instead) at all. Purely
/// presentational: the actual checkout call only happens after
/// [onConfirm]/[onTestPayment] is invoked (see `BillingPage._openCheckout`).
/// Tapping a method card both confirms the choice and starts checkout in
/// one tap — no separate "confirm" step, matching the brief's
/// minimal-taps goal.
class PaymentSummaryDialog extends StatelessWidget {
  const PaymentSummaryDialog({
    required this.cart,
    required this.merchantName,
    required this.storeName,
    required this.onConfirm,
    required this.onTestPayment,
    this.customer,
    super.key,
  });

  final BillingState cart;
  final String merchantName;
  final String storeName;

  /// Optional walk-in customer info captured by the Customer Details step
  /// right before this dialog — shown here for the merchant's confirmation,
  /// then carried through to the Receipt (see `CustomerDetails`'s own
  /// header comment).
  final CustomerDetails? customer;

  final VoidCallback onConfirm;

  /// Development-only — simulates a successful payment completely offline,
  /// never touching the real Surfboard checkout path (see
  /// docs/22_DEVELOPMENT_ROADMAP.md Phase 4.5).
  final VoidCallback onTestPayment;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Payment Summary', style: AppTypography.headingMD),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(label: 'Merchant', value: merchantName),
                _InfoRow(label: 'Store', value: storeName),
                if (customer != null && !customer!.isEmpty)
                  _InfoRow(
                    label: 'Customer',
                    value: [
                      if (customer!.name != null) customer!.name!,
                      if (customer!.phone != null) customer!.phone!,
                    ].join(' · '),
                  ),
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
                const SizedBox(height: AppSpacing.lg),
                Text('Choose a payment method',
                    style: AppTypography.bodySM
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                _PaymentMethodCard(
                  icon: LucideIcons.creditCard,
                  title: 'Surfboard',
                  subtitle: 'Card payment via Surfboard\'s hosted page',
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _PaymentMethodCard(
                  icon: LucideIcons.flaskConical,
                  title: 'Test Payment',
                  subtitle: 'Simulates a successful payment offline',
                  badge:
                      const StatusChip(label: 'DEV', tone: StatusTone.warning),
                  onTap: () {
                    Navigator.of(context).pop();
                    onTestPayment();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const _PaymentMethodCard(
                  icon: LucideIcons.banknote,
                  title: 'Cash',
                  subtitle: 'Take a cash payment',
                  badge: StatusChip(label: 'Coming Soon'),
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
              boxShadow: enabled ? AppShadows.subtle : null,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.bodyLG
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  badge!,
                ] else if (enabled)
                  const Icon(LucideIcons.chevronRight,
                      size: 18, color: AppColors.textGrey),
              ],
            ),
          ),
        ),
      ),
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
