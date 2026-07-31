import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../../core/widgets/text_fields/app_search_field.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/pages/add_product_page.dart';
import '../../payments/models/checkout_item.dart';
import '../../payments/pages/payment_status_page.dart';
import '../../payments/widgets/payment_summary_dialog.dart';
import '../controllers/billing_controller.dart';
import '../models/billing_state.dart';
import '../providers/billing_providers.dart';
import '../widgets/billing_summary_card.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/product_not_found_banner.dart';
import '../widgets/search_suggestions_list.dart';
import 'barcode_scanner_page.dart';

/// The Billing tab's root screen — search-or-scan product entry, the
/// shopping cart, and the totals/checkout/payment flow (see
/// docs/22_DEVELOPMENT_ROADMAP.md, Phase 4). This screen owns Checkout's
/// entry point (the Payment Summary confirmation); the actual Surfboard
/// order/payment orchestration lives in `features/payments/`.
class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, String uid) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(billingControllerProvider(uid).notifier).search(value);
    });
  }

  void _selectSuggestion(String uid, ProductModel product) {
    _searchController.clear();
    ref
        .read(billingControllerProvider(uid).notifier)
        .selectSearchResult(product);
    _searchFocusNode.unfocus();
  }

  Future<void> _openScanner(String uid) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage(uid: uid)),
    );
  }

  void _searchManually(String uid) {
    ref.read(billingControllerProvider(uid).notifier).dismissNotFound();
    _searchFocusNode.requestFocus();
  }

  void _addProductFromNotFound(String uid) {
    ref.read(billingControllerProvider(uid).notifier).dismissNotFound();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddProductPage()));
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const AppFullScreenLoader();
    }

    final provider = billingControllerProvider(uid);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen(provider.select((s) => s.lastAddedProductName),
        (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Product Added: $next')),
        );
        notifier.dismissLastAdded();
      }
    });

    final isSearchingView = state.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: const AppTopBar(title: 'Billing'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                hint: 'Search by name, SKU, or barcode',
                controller: _searchController,
                autofocus: false,
                onChanged: (value) => _onSearchChanged(value, uid),
                onScanTap: () => _openScanner(uid),
              ),
              if (state.notFoundBarcode != null)
                ProductNotFoundBanner(
                  barcode: state.notFoundBarcode!,
                  onSearchManually: () => _searchManually(uid),
                  onAddProduct: () => _addProductFromNotFound(uid),
                  onDismiss: notifier.dismissNotFound,
                ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: isSearchingView
                    ? SearchSuggestionsList(
                        results: state.searchResults,
                        isSearching: state.isSearching,
                        errorMessage: state.searchError,
                        onSelect: (product) => _selectSuggestion(uid, product),
                      )
                    : _CartList(state: state, notifier: notifier),
              ),
              const SizedBox(height: AppSpacing.sm),
              BillingSummaryCard(
                state: state,
                onClearCart: () => _confirmClearCart(uid),
                onCheckout: () => _openCheckout(uid, state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckout(String uid, BillingState cart) {
    final dashboard = ref.read(dashboardControllerProvider(uid)).valueOrNull;
    final storeId = dashboard?.store?.id;
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up a store before taking payments.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => PaymentSummaryDialog(
        cart: cart,
        merchantName: dashboard?.merchant?.name ?? '—',
        storeName: dashboard?.store?.name ?? '—',
        onConfirm: () => _startPaymentFlow(uid, storeId, cart),
      ),
    );
  }

  void _startPaymentFlow(String uid, String storeId, BillingState cart) {
    final items = [
      for (final item in cart.items)
        CheckoutItem(productId: item.product.id, quantity: item.quantity),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          uid: uid,
          storeId: storeId,
          items: items,
          onDone: () {
            ref.read(billingControllerProvider(uid).notifier).clearCart();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes every item from the current bill.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear Cart')),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(billingControllerProvider(uid).notifier).clearCart();
    }
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.state, required this.notifier});

  final BillingState state;
  final BillingController notifier;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.shoppingCart,
        title: 'Cart is Empty',
        message: 'Search for a product or scan a barcode to start a new bill.',
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return CartItemTile(
          item: item,
          onIncrease: () => notifier.increaseQuantity(item.product.id),
          onDecrease: () => notifier.decreaseQuantity(item.product.id),
          onDelete: () => notifier.removeItem(item.product.id),
        );
      },
    );
  }
}
