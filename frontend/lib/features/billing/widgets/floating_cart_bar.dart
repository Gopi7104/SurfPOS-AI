import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../models/billing_state.dart';

/// The sticky bottom surface every screen redesign brief in this family
/// calls "always visible" — a subtle "Cart is Empty" hint with nothing in
/// the cart, otherwise the running total plus the single "Proceed to
/// Payment" tap the checkout flow needs. Tapping the item-count row (not
/// the button) opens the full cart via [onExpand]; tapping the button
/// itself goes straight into [onCheckout] — no need to open the cart first
/// for a merchant who's happy with what's already in it.
class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({
    required this.state,
    required this.onExpand,
    required this.onCheckout,
    super.key,
  });

  final BillingState state;
  final VoidCallback onExpand;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevated,
      ),
      child: state.isEmpty ? _emptyHint() : _cartSummary(),
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(LucideIcons.shoppingCart,
              size: 20, color: AppColors.textGrey),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cart is Empty',
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                    'Search for a product or scan a barcode to start a new bill.',
                    style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onExpand,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(LucideIcons.shoppingCart,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                      '${state.itemCount} item${state.itemCount == 1 ? '' : 's'}',
                      style: AppTypography.bodySM
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('View Cart', style: AppTypography.caption),
                  const Icon(LucideIcons.chevronUp,
                      size: 16, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Total',
                style:
                    AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
            const Spacer(),
            CountUpNumber(
              value: state.grandTotal,
              formatter: (v) => '\$${v.toStringAsFixed(2)}',
              style: AppTypography.numberLG.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppPrimaryButton(
          label: 'Proceed to Payment',
          icon: LucideIcons.arrowRight,
          onPressed: onCheckout,
        ),
      ],
    );
  }
}
