import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/glass_header.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../../core/widgets/text_fields/app_search_field.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../inventory/controllers/inventory_list_state.dart';
import '../../inventory/models/inventory_query.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/pages/add_product_page.dart';
import '../../inventory/pages/product_details_page.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../../payments/models/checkout_item.dart';
import '../../payments/pages/payment_status_page.dart';
import '../../payments/pages/test_payment_status_page.dart';
import '../../payments/widgets/payment_summary_dialog.dart';
import '../../receipt/models/receipt_line_item.dart';
import '../models/billing_state.dart';
import '../models/customer_details.dart';
import '../providers/billing_providers.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/customer_details_sheet.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_not_found_banner.dart';
import '../widgets/search_suggestions_list.dart';
import 'barcode_scanner_page.dart';

/// The Billing tab's root screen — search-or-scan product entry, a
/// category-filtered product grid, the floating cart, and the totals/
/// checkout/payment flow (see docs/22_DEVELOPMENT_ROADMAP.md, Phase 4, and
/// the Phase UI/UX 3 redesign brief). This screen owns Checkout's entry
/// point (the optional Customer Details step, then the Payment Summary
/// confirmation); the actual Surfboard order/payment orchestration lives in
/// `features/payments/`.
class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _clockTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  Future<void> _showQuickActions(ProductModel product) {
    return showAppBottomSheet<void>(
      context: context,
      title: product.name,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading:
                const Icon(LucideIcons.squarePen, color: AppColors.primary),
            title: const Text('View / Edit in Inventory'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(productId: product.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openCart(String uid, BillingState state) {
    final notifier = ref.read(billingControllerProvider(uid).notifier);
    showCartBottomSheet(
      context: context,
      state: state,
      onIncrease: notifier.increaseQuantity,
      onDecrease: notifier.decreaseQuantity,
      onRemove: notifier.removeItem,
      onClearCart: () => _confirmClearCart(uid),
      onCheckout: () => _openCheckout(uid, state),
    );
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

    final dashboard = ref.watch(dashboardControllerProvider(uid)).valueOrNull;
    final merchantName = dashboard?.merchant?.name ?? 'Merchant';
    final storeName = dashboard?.store?.name ?? 'Store';

    final isSearchingView = state.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GlassHeader(
              title: storeName,
              subtitle: _timeLabel,
              avatarLabel: merchantName,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    icon: LucideIcons.search,
                    onTap: _searchFocusNode.requestFocus,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HeaderIconButton(
                    icon: LucideIcons.scanLine,
                    onTap: () => _openScanner(uid),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search by name, SKU, or barcode',
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    onChanged: (value) => _onSearchChanged(value, uid),
                    onScanTap: () => _openScanner(uid),
                  ),
                  if (state.notFoundBarcode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: ProductNotFoundBanner(
                        barcode: state.notFoundBarcode!,
                        onSearchManually: () => _searchManually(uid),
                        onAddProduct: () => _addProductFromNotFound(uid),
                        onDismiss: notifier.dismissNotFound,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: isSearchingView
                  ? Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: SearchSuggestionsList(
                        results: state.searchResults,
                        isSearching: state.isSearching,
                        errorMessage: state.searchError,
                        onSelect: (product) => _selectSuggestion(uid, product),
                      ),
                    )
                  : _ProductBrowseView(
                      uid: uid,
                      onProductTap: (product) =>
                          notifier.selectSearchResult(product),
                      onProductLongPress: _showQuickActions,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: FloatingCartBar(
                state: state,
                onExpand: () => _openCart(uid, state),
                onCheckout: () => _openCheckout(uid, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCheckout(String uid, BillingState cart) async {
    final dashboard = ref.read(dashboardControllerProvider(uid)).valueOrNull;
    final storeId = dashboard?.store?.id;
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up a store before taking payments.')),
      );
      return;
    }

    final merchantName = dashboard?.merchant?.name ?? '—';
    final storeName = dashboard?.store?.name ?? '—';

    final customer = await showCustomerDetailsSheet(context, uid: uid);
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => PaymentSummaryDialog(
        cart: cart,
        merchantName: merchantName,
        storeName: storeName,
        customer: customer,
        onConfirm: () => _startPaymentFlow(
            uid, storeId, cart, merchantName, storeName, customer),
        onTestPayment: () =>
            _confirmTestPayment(uid, cart, merchantName, storeName, customer),
      ),
    );
  }

  Future<void> _confirmTestPayment(String uid, BillingState cart,
      String merchantName, String storeName, CustomerDetails? customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete a simulated payment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Complete Payment')),
        ],
      ),
    );
    if (confirmed == true) {
      _startTestPaymentFlow(uid, cart, merchantName, storeName, customer);
    }
  }

  void _startTestPaymentFlow(String uid, BillingState cart, String merchantName,
      String storeName, CustomerDetails? customer) {
    final receiptItems = [
      for (final item in cart.items)
        ReceiptLineItem(
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.lineTotal,
          productId: item.product.id,
          category: item.product.category,
        ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestPaymentStatusPage(
          uid: uid,
          merchantName: merchantName,
          storeName: storeName,
          receiptItems: receiptItems,
          subtotal: cart.subtotal,
          discountTotal: cart.discountTotal,
          taxTotal: cart.taxTotal,
          grandTotal: cart.grandTotal,
          customerName: customer?.name,
          customerPhone: customer?.phone,
          customerId: customer?.customerId,
          onDone: () {
            ref.read(billingControllerProvider(uid).notifier).clearCart();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startPaymentFlow(String uid, String storeId, BillingState cart,
      String merchantName, String storeName, CustomerDetails? customer) {
    final items = [
      for (final item in cart.items)
        CheckoutItem(productId: item.product.id, quantity: item.quantity),
    ];
    final receiptItems = [
      for (final item in cart.items)
        ReceiptLineItem(
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.lineTotal,
          productId: item.product.id,
          category: item.product.category,
        ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          uid: uid,
          storeId: storeId,
          items: items,
          merchantName: merchantName,
          storeName: storeName,
          receiptItems: receiptItems,
          customerName: customer?.name,
          customerPhone: customer?.phone,
          customerId: customer?.customerId,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.white),
        ),
      ),
    );
  }
}

/// Category chips + the product grid — the default (non-searching) Billing
/// view. Pulls from Inventory's own `inventoryListControllerProvider`/
/// `inventoryCategoriesProvider` (already built for `ProductListPage`,
/// unmodified here) rather than re-implementing catalog browsing inside
/// Billing.
class _ProductBrowseView extends ConsumerStatefulWidget {
  const _ProductBrowseView({
    required this.uid,
    required this.onProductTap,
    required this.onProductLongPress,
  });

  final String uid;
  final ValueChanged<ProductModel> onProductTap;
  final ValueChanged<ProductModel> onProductLongPress;

  @override
  ConsumerState<_ProductBrowseView> createState() => _ProductBrowseViewState();
}

class _ProductBrowseViewState extends ConsumerState<_ProductBrowseView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    ref
        .read(inventoryListControllerProvider(widget.uid).notifier)
        .loadMore()
        .catchError((Object error) {});
  }

  void _onCategorySelected(String? category) {
    final current = ref
            .read(inventoryListControllerProvider(widget.uid))
            .valueOrNull
            ?.query ??
        const InventoryQuery();
    ref.read(inventoryListControllerProvider(widget.uid).notifier).applyQuery(
          category == null
              ? current.copyWith(clearCategory: true)
              : current.copyWith(category: category),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryListControllerProvider(widget.uid));
    final categories =
        ref.watch(inventoryCategoriesProvider(widget.uid)).valueOrNull ??
            const <String>[];
    final selectedCategory = state.valueOrNull?.query.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: CategoryChipBar(
            categories: categories,
            selectedCategory: selectedCategory,
            onSelected: _onCategorySelected,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: switch (state) {
            AsyncLoading() when !state.hasValue =>
              const Center(child: AppLoadingIndicator()),
            AsyncError() when !state.hasValue => ErrorState(
                message:
                    'Could not load your products. Please check your connection and try again.',
                onRetry: () => ref
                    .read(inventoryListControllerProvider(widget.uid).notifier)
                    .refresh(),
              ),
            _ => _buildGrid(state.value!),
          },
        ),
      ],
    );
  }

  Widget _buildGrid(InventoryListState data) {
    if (data.items.isEmpty) {
      return data.query.hasActiveFilters
          ? const EmptyState(
              icon: LucideIcons.searchX,
              title: 'No Results',
              message: 'No products match this category.',
            )
          : const EmptyState(
              icon: LucideIcons.package,
              title: 'No Products',
              message: 'Add products in Inventory to start selling.',
            );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  (constraints.maxWidth / 170).floor().clamp(2, 6);
              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                ),
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final product = data.items[index];
                  return ProductGridCard(
                    product: product,
                    onTap: () => widget.onProductTap(product),
                    onLongPress: () => widget.onProductLongPress(product),
                  );
                },
              );
            },
          ),
        ),
        if (data.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppLoadingIndicator(),
          ),
      ],
    );
  }
}
