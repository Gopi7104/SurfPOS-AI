import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/product_model.dart';
import '../models/product_status.dart';
import '../providers/inventory_providers.dart';
import 'edit_product_page.dart';

/// Product Details — every field, an Edit action, and a soft-delete action
/// behind a confirmation dialog (so a merchant never loses a product by a
/// stray tap).
class ProductDetailsPage extends ConsumerWidget {
  const ProductDetailsPage({required this.productId, super.key});

  final String productId;

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this product?'),
        content: const Text(
            'This removes it from your catalog. This cannot be undone from here.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(inventoryListControllerProvider(uid).notifier)
          .deleteProduct(productId);
      ref.invalidate(inventoryCategoriesProvider(uid));
      ref.invalidate(inventoryStatsProvider(uid));
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not delete this product. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final key = (uid: uid, productId: productId);
    final productAsync = ref.watch(productDetailsProvider(key));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Product Details', onBack: () => Navigator.of(context).pop()),
      body: switch (productAsync) {
        AsyncLoading() when !productAsync.hasValue => const AppFullScreenBody(),
        AsyncError() when !productAsync.hasValue => ErrorState(
            message: 'Could not load this product.',
            onRetry: () => ref.invalidate(productDetailsProvider(key)),
          ),
        _ => _ProductDetailsBody(
            product: productAsync.value!,
            onEdit: () async {
              final updated = await Navigator.of(context).push<ProductModel>(
                MaterialPageRoute(
                    builder: (_) =>
                        EditProductPage(product: productAsync.value!)),
              );
              if (updated != null) ref.invalidate(productDetailsProvider(key));
            },
            onDelete: () => _confirmDelete(context, ref, uid),
          ),
      },
    );
  }
}

/// Local full-body loading view — avoids importing [AppFullScreenLoader]
/// just to wrap it in a `Center`, since it's already centered itself.
class AppFullScreenBody extends StatelessWidget {
  const AppFullScreenBody({super.key});

  @override
  Widget build(BuildContext context) => const AppLoadingIndicator();
}

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody(
      {required this.product, required this.onEdit, required this.onDelete});

  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SectionCard(
          title: product.name,
          trailing: StatusChip(
            label: product.status.label,
            tone: product.status == ProductStatus.active
                ? StatusTone.success
                : StatusTone.neutral,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (product.description != null) ...[
                Text(product.description!,
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.textGrey)),
                const SizedBox(height: AppSpacing.md),
              ],
              _DetailRow(label: 'SKU', value: product.sku),
              _DetailRow(label: 'Barcode', value: product.barcode ?? '—'),
              _DetailRow(label: 'Category', value: product.category ?? '—'),
              _DetailRow(label: 'Unit', value: product.unit),
              _DetailRow(
                  label: 'Price',
                  value: '\$${product.price.toStringAsFixed(2)}'),
              _DetailRow(
                  label: 'Cost Price',
                  value: '\$${product.costPrice.toStringAsFixed(2)}'),
              _DetailRow(
                  label: 'Tax',
                  value: '${product.taxPercentage.toStringAsFixed(1)}%'),
              _DetailRow(
                  label: 'Discount',
                  value: '${product.discountPercentage.toStringAsFixed(1)}%'),
              _DetailRow(
                  label: 'Stock',
                  value: '${product.stockQuantity} ${product.unit}'),
              _DetailRow(
                label: 'Low Stock Alert',
                value: product.lowStockThreshold?.toString() ?? 'Not set',
              ),
              if (product.isOutOfStock)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child:
                      StatusChip(label: 'Out of Stock', tone: StatusTone.error),
                )
              else if (product.isLowStock)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child:
                      StatusChip(label: 'Low Stock', tone: StatusTone.warning),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(label: 'Edit Product', onPressed: onEdit),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Delete Product'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
