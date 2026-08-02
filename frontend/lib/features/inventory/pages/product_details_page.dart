import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import '../widgets/product_quick_actions_sheet.dart';
import '../widgets/product_thumbnail.dart';
import '../widgets/stock_movement_timeline.dart';
import 'edit_product_page.dart';

/// Product Details — every field, a Stock Movement timeline (always the
/// "no history yet" placeholder — see `StockMovementTimeline`'s header
/// comment), Quick Actions parity with the catalog cards, and a
/// soft-delete action behind a confirmation dialog.
class ProductDetailsPage extends ConsumerWidget {
  const ProductDetailsPage({required this.productId, super.key});

  final String productId;

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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Product Details',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          if (productAsync.hasValue)
            IconButton(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert),
              onPressed: () => showProductQuickActionsSheet(context,
                  uid: uid, product: productAsync.value!),
            ),
        ],
      ),
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
  const _ProductDetailsBody({required this.product, required this.onEdit});

  final ProductModel product;
  final VoidCallback onEdit;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _GalleryHeader(product: product),
        const SizedBox(height: AppSpacing.md),
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
              if (product.isOutOfStock)
                const StatusChip(label: 'Out of Stock', tone: StatusTone.error)
              else if (product.isLowStock)
                const StatusChip(label: 'Low Stock', tone: StatusTone.warning),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(label: 'SKU', value: product.sku),
              _DetailRow(label: 'Barcode', value: product.barcode ?? '—'),
              _DetailRow(label: 'Category', value: product.category ?? '—'),
              _DetailRow(label: 'Unit', value: product.unit),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Pricing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Stock',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                  label: 'Current Stock',
                  value: '${product.stockQuantity} ${product.unit}'),
              _DetailRow(
                label: 'Low Stock Alert',
                value: product.lowStockThreshold?.toString() ?? 'Not set',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Supplier',
          trailing: const StatusChip(label: 'Coming Soon'),
          child: Text(
            'Supplier details aren\'t tracked yet — this section is reserved '
            'for a future update.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionCard(
          title: 'Stock Movement',
          child: StockMovementTimeline(),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                  label: 'Created', value: _formatDate(product.createdAt)),
              _DetailRow(
                  label: 'Last Updated', value: _formatDate(product.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(label: 'Edit Product', onPressed: onEdit),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Large product image + a gallery strip — only one real photo exists on
/// [ProductModel] today, so the remaining tiles are disabled "Add Photo"
/// placeholders for a future multi-image gallery.
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 1.4,
            child:
                ProductThumbnail(product: product, size: null, borderRadius: 0),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ProductThumbnail(product: product, size: 56),
              const SizedBox(width: AppSpacing.sm),
              for (var i = 0; i < 3; i++) ...[
                const _AddPhotoPlaceholder(),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoPlaceholder extends StatelessWidget {
  const _AddPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.disabledSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(LucideIcons.imagePlus,
          size: 20, color: AppColors.textGrey),
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
