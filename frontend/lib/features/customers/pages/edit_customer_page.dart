import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/customer_failure.dart';
import '../models/customer_model.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_form.dart';

/// Edit Customer — same [CustomerForm] as Add, pre-filled from [customer]
/// and submitting via [CustomerFormController.updateCustomer], mirroring
/// `EditProductPage`.
class EditCustomerPage extends ConsumerWidget {
  const EditCustomerPage({required this.customer, super.key});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final provider = customerFormControllerProvider(uid);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.hasValue && next.value != null) {
        ref.invalidate(customerListControllerProvider(uid));
        ref.invalidate(customerStatsProvider(uid));
        Navigator.of(context).pop(next.value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated.')),
        );
      }
    });

    return Scaffold(
      appBar: AppTopBar(
          title: 'Edit Customer', onBack: () => Navigator.of(context).pop()),
      body: CustomerForm(
        initial: customer,
        submitLabel: 'Save Changes',
        isSubmitting: state.isLoading,
        errorMessage: state.hasError
            ? CustomerFailure.fromException(state.error!).message
            : null,
        onSubmit: (draft) =>
            ref.read(provider.notifier).updateCustomer(customer.id, draft),
      ),
    );
  }
}
