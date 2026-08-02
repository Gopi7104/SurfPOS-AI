import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_empty_state.dart';
import '../widgets/purchase_history_tile.dart';

/// The full Purchase History for one customer — reached from Customer
/// Details' "View All". Always empty today (see
/// `CustomerRepositoryImpl.getPurchaseHistory`'s header comment); built
/// against the same cursor-paginated repository shape a real purchase
/// history would use, so this page needs no change once one exists.
class PurchaseHistoryPage extends ConsumerWidget {
  const PurchaseHistoryPage({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final key = (uid: uid, customerId: customerId);
    final purchasesAsync = ref.watch(customerPurchaseHistoryProvider(key));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Purchase History', onBack: () => Navigator.of(context).pop()),
      body: SafeArea(
        child: switch (purchasesAsync) {
          AsyncLoading() when !purchasesAsync.hasValue =>
            const Center(child: AppLoadingIndicator()),
          AsyncError() when !purchasesAsync.hasValue => ErrorState(
              message: 'Could not load purchase history.',
              onRetry: () =>
                  ref.invalidate(customerPurchaseHistoryProvider(key)),
            ),
          _ => purchasesAsync.value!.isEmpty
              ? const CustomerEmptyState(
                  icon: LucideIcons.receipt,
                  title: 'No purchases yet',
                  message: 'Completed purchases will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: purchasesAsync.value!.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => PurchaseHistoryTile(
                      purchase: purchasesAsync.value![index]),
                ),
        },
      ),
    );
  }
}
