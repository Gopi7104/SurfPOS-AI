import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../models/billing_state.dart';
import 'billing_summary_card.dart';
import 'cart_item_tile.dart';

/// The full, editable cart — opened from [FloatingCartBar]'s "View Cart"
/// row. Every row supports swipe-to-remove via [Dismissible] in addition to
/// [CartItemTile]'s own delete icon; "Proceed to Payment" here does exactly
/// what the main screen's sticky button does (closes the sheet first, then
/// hands off to the same [onCheckout] callback) — a merchant reviewing the
/// cart never needs a second, different path to pay.
Future<void> showCartBottomSheet({
  required BuildContext context,
  required BillingState state,
  required ValueChanged<String> onIncrease,
  required ValueChanged<String> onDecrease,
  required ValueChanged<String> onRemove,
  required VoidCallback onClearCart,
  required VoidCallback onCheckout,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Your Cart',
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.75,
      child: _CartBottomSheetBody(
        state: state,
        onIncrease: onIncrease,
        onDecrease: onDecrease,
        onRemove: onRemove,
        onClearCart: onClearCart,
        onCheckout: onCheckout,
      ),
    ),
  );
}

class _CartBottomSheetBody extends StatelessWidget {
  const _CartBottomSheetBody({
    required this.state,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onClearCart,
    required this.onCheckout,
  });

  final BillingState state;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: state.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.shoppingCart,
                  title: 'Cart is Empty',
                  message:
                      'Search for a product or scan a barcode to start a new bill.',
                )
              : ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Dismissible(
                      key: ValueKey(item.product.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => onRemove(item.product.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(LucideIcons.trash2,
                            color: AppColors.error),
                      ),
                      child: CartItemTile(
                        item: item,
                        onIncrease: () => onIncrease(item.product.id),
                        onDecrease: () => onDecrease(item.product.id),
                        onDelete: () => onRemove(item.product.id),
                      ),
                    );
                  },
                ),
        ),
        if (!state.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          BillingSummaryCard(state: state),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Proceed to Payment',
            icon: LucideIcons.arrowRight,
            onPressed: () {
              Navigator.of(context).pop();
              onCheckout();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClearCart();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear Cart'),
            ),
          ),
        ],
      ],
    );
  }
}
