import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/inventory_failure.dart';
import '../models/product_model.dart';
import '../providers/inventory_providers.dart';
import '../widgets/product_form.dart';

/// Edit Product — same [ProductForm] as Add, pre-filled from [product] and
/// submitting via [InventoryFormController.update].
class EditProductPage extends ConsumerWidget {
  const EditProductPage({required this.product, super.key});

  final ProductModel product;

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
        Navigator.of(context).pop(next.value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated.')),
        );
      }
    });

    return Scaffold(
      appBar: AppTopBar(
          title: 'Edit Product', onBack: () => Navigator.of(context).pop()),
      body: ProductForm(
        uid: uid,
        initial: product,
        submitLabel: 'Save Changes',
        isSubmitting: state.isLoading,
        errorMessage: state.hasError
            ? InventoryFailure.fromException(state.error!).message
            : null,
        onSubmit: (result) {
          final storeId =
              ref.read(dashboardControllerProvider(uid)).valueOrNull?.store?.id;
          ref.read(provider.notifier).updateProduct(
                product.id,
                result.draft,
                stockDelta: result.stockQuantity - product.stockQuantity,
                storeId: storeId,
              );
        },
      ),
    );
  }
}
