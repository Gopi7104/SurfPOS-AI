import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/cart_item_model.dart';
import 'product_thumbnail.dart';

/// One cart row — product image, name, quantity controls, unit price, line
/// total, and a delete action. All mutation is delegated to the caller
/// (which calls into [BillingController]) — this widget only renders
/// [item] and reports taps, no business logic. Swipe-to-remove is the
/// enclosing list's job (see `CartBottomSheet`'s `Dismissible` wrapper);
/// [onDelete] stays as the always-reachable non-gesture fallback.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
    super.key,
  });

  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumbnail(product: item.product, size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTypography.bodyLG
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.textGrey),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuantityStepper(
                  quantity: item.quantity,
                  onIncrease: onIncrease,
                  onDecrease: item.quantity > 1 ? onDecrease : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: AppTypography.bodyLG.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2,
                    size: 20, color: AppColors.error),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper(
      {required this.quantity, required this.onIncrease, this.onDecrease});

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: LucideIcons.minus, onTap: onDecrease),
        SizedBox(
          width: 32,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(quantity),
            tween: Tween(begin: 1.3, end: 1.0),
            duration: AppMotion.medium,
            curve: AppMotion.curve.emphasized,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _StepperButton(icon: LucideIcons.plus, onTap: onIncrease),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          onTap == null ? AppColors.disabledSurface : AppColors.primarySubtle,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 16,
              color: onTap == null ? AppColors.textGrey : AppColors.primary),
        ),
      ),
    );
  }
}
