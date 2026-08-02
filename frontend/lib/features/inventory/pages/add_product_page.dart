import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/inventory_failure.dart';
import '../models/product_lookup_result.dart';
import '../models/product_model.dart';
import '../models/product_status.dart';
import '../providers/inventory_providers.dart';
import '../widgets/product_form.dart';

/// Add Product — a thin Riverpod wrapper around [ProductForm] that submits
/// via [InventoryFormController.create] and pops back to the Product List
/// on success, mirroring `MerchantOnboardingWizardPage`'s screen/page split.
class AddProductPage extends ConsumerWidget {
  const AddProductPage({this.prefill, this.duplicateFrom, super.key});

  /// A successful barcode scan's resolved product info — threaded straight
  /// through to [ProductForm]; `null` for the plain "Enter Manually" path.
  final ProductLookupResult? prefill;

  /// Quick Actions' "Duplicate" — pre-fills every field from an existing
  /// catalog product *except* SKU/barcode (cleared, since those must stay
  /// unique per product) and stock (reset to 0, since a duplicate is a new
  /// physical batch the merchant hasn't counted yet). Still submits via the
  /// same [InventoryFormController.create] as a brand-new product — see
  /// `product_quick_actions_sheet.dart`'s header comment.
  final ProductModel? duplicateFrom;

  ProductModel? get _initial {
    final source = duplicateFrom;
    if (source == null) return null;
    return ProductModel(
      id: '',
      merchantId: source.merchantId,
      name: source.name,
      description: source.description,
      sku: '',
      barcode: null,
      category: source.category,
      unit: source.unit,
      price: source.price,
      costPrice: source.costPrice,
      taxPercentage: source.taxPercentage,
      discountPercentage: source.discountPercentage,
      lowStockThreshold: source.lowStockThreshold,
      stockQuantity: 0,
      imageUrl: source.imageUrl,
      imagePath: source.imagePath,
      status: ProductStatus.active,
      isActive: true,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = inventoryFormControllerProvider(uid);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.hasValue && next.value != null) {
        ref.invalidate(inventoryListControllerProvider(uid));
        ref.invalidate(inventoryCategoriesProvider(uid));
        ref.invalidate(inventoryStatsProvider(uid));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added.')),
        );
      }
    });

    return Scaffold(
      appBar: AppTopBar(
          title: 'Add Product', onBack: () => Navigator.of(context).pop()),
      body: ProductForm(
        uid: uid,
        initial: _initial,
        prefill: prefill,
        submitLabel: 'Save',
        isSubmitting: state.isLoading,
        errorMessage: state.hasError
            ? InventoryFailure.fromException(state.error!).message
            : null,
        onSubmit: (result) {
          final storeId =
              ref.read(dashboardControllerProvider(uid)).valueOrNull?.store?.id;
          ref.read(provider.notifier).create(
                result.draft,
                initialStock: result.stockQuantity,
                storeId: storeId,
              );
        },
      ),
    );
  }
}
