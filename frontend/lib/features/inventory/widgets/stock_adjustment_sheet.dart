import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/product_model.dart';
import '../providers/inventory_providers.dart';
import 'product_draft_from_model.dart';

/// Shared one-field bottom sheet for any stock-quantity change — Low
/// Stock's "Quick Restock" (add-only) and the product Quick Actions sheet's
/// "Adjust Stock" (add or subtract) are the same mechanism with different
/// copy/sign. Submits via the existing
/// `InventoryFormController.updateProduct(stockDelta:)` — the same
/// `adjustStock` composition Edit Product already uses; the resent
/// [ProductDraft] carries the product's own unchanged field values (see
/// `draftFromProduct`), so the only real effect is the stock delta.
Future<void> showStockAdjustmentSheet(
  BuildContext context, {
  required String uid,
  required ProductModel product,
  required bool allowNegative,
}) {
  final controller = TextEditingController();
  final title = allowNegative ? 'Adjust Stock' : 'Restock';
  final submitLabel = allowNegative ? 'Save Adjustment' : 'Add Stock';
  final hint = allowNegative ? 'e.g. 20 or -5' : 'e.g. 20';

  Future<void> submit(BuildContext sheetContext, WidgetRef sheetRef) async {
    final delta = int.tryParse(controller.text.trim());
    if (delta == null || delta == 0) return;
    if (!allowNegative && delta < 0) return;

    final storeId =
        sheetRef.read(dashboardControllerProvider(uid)).valueOrNull?.store?.id;
    if (storeId == null) return;

    await sheetRef
        .read(inventoryFormControllerProvider(uid).notifier)
        .updateProduct(
          product.id,
          draftFromProduct(product),
          stockDelta: delta,
          storeId: storeId,
        );

    final succeeded =
        !sheetRef.read(inventoryFormControllerProvider(uid)).hasError;
    if (succeeded && sheetContext.mounted) {
      sheetRef.invalidate(inventoryListControllerProvider(uid));
      sheetRef.invalidate(inventoryStatsProvider(uid));
      Navigator.of(sheetContext).pop();
    }
  }

  return showAppBottomSheet<void>(
    context: context,
    title: '$title ${product.name}',
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, sheetRef, _) {
        final formState = sheetRef.watch(inventoryFormControllerProvider(uid));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Currently ${product.stockQuantity} ${product.unit} in stock.',
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: allowNegative ? 'Quantity change' : 'Quantity to add',
              hint: hint,
              controller: controller,
              keyboardType:
                  TextInputType.numberWithOptions(signed: allowNegative),
            ),
            if (formState.hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Could not update stock. Please try again.',
                  style: AppTypography.bodySM.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: submitLabel,
              isLoading: formState.isLoading,
              onPressed: formState.isLoading
                  ? null
                  : () => submit(sheetContext, sheetRef),
            ),
          ],
        );
      },
    ),
  );
}
