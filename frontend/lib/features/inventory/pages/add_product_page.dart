import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/inventory_failure.dart';
import '../providers/inventory_providers.dart';
import '../widgets/product_form.dart';

/// Add Product — a thin Riverpod wrapper around [ProductForm] that submits
/// via [InventoryFormController.create] and pops back to the Product List
/// on success, mirroring `MerchantOnboardingWizardPage`'s screen/page split.
class AddProductPage extends ConsumerWidget {
  const AddProductPage({super.key});

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
