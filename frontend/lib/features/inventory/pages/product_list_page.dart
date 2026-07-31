import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_fab.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../../core/widgets/loading/skeleton_list.dart';
import '../../../core/widgets/text_fields/app_search_field.dart';
import '../../authentication/providers/auth_providers.dart';
import '../controllers/inventory_list_controller.dart';
import '../models/inventory_query.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/product_card.dart';
import 'add_product_page.dart';
import 'product_details_page.dart';

/// Search + filter + paginated product grid — the Product List page from
/// the Phase 2 brief. Search-bar/category/stock filters/sort all live in
/// one [InventoryQuery] the controller re-fetches from on every change;
/// infinite scroll appends pages, pull-to-refresh reloads page one.
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({this.initialCategory, super.key});

  /// Pre-applies a category filter — used when arriving from the
  /// Categories page.
  final String? initialCategory;

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialCategory != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyInitialCategory());
    }
  }

  void _applyInitialCategory() {
    final uid = ref.read(authControllerProvider).valueOrNull?.uid;
    if (uid == null) return;
    ref
        .read(inventoryListControllerProvider(uid).notifier)
        .applyQuery(InventoryQuery(category: widget.initialCategory));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    final uid = ref.read(authControllerProvider).valueOrNull?.uid;
    if (uid == null) return;
    ref
        .read(inventoryListControllerProvider(uid).notifier)
        .loadMore()
        .catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not load more products. Pull down to try again.')),
      );
    });
  }

  void _onSearchChanged(String value, String uid) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final current =
          ref.read(inventoryListControllerProvider(uid)).valueOrNull?.query ??
              const InventoryQuery();
      ref.read(inventoryListControllerProvider(uid).notifier).applyQuery(
          current.copyWith(search: value, clearSearch: value.isEmpty));
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) return const AppFullScreenLoader();

    final provider = inventoryListControllerProvider(uid);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final categories =
        ref.watch(inventoryCategoriesProvider(uid)).valueOrNull ??
            const <String>[];

    return Scaffold(
      appBar: AppTopBar(
          title: 'Products', onBack: () => Navigator.of(context).pop()),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AppFab(
        icon: Icons.add_rounded,
        label: 'Add Product',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddProductPage()),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                hint: 'Search by name, SKU, or barcode',
                controller: _searchController,
                onChanged: (value) => _onSearchChanged(value, uid),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.hasValue)
                InventoryFilterBar(
                  query: state.value!.query,
                  categories: categories,
                  onQueryChanged: notifier.applyQuery,
                ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: switch (state) {
                  AsyncLoading() when !state.hasValue => const SkeletonList(),
                  AsyncError() when !state.hasValue => ErrorState(
                      message:
                          'Could not load your products. Please check your connection and try again.',
                      onRetry: notifier.refresh,
                    ),
                  _ => _ProductListBody(
                      data: state.value!,
                      notifier: notifier,
                      scrollController: _scrollController,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody(
      {required this.data,
      required this.notifier,
      required this.scrollController});

  final InventoryListState data;
  final InventoryListController notifier;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: data.query.hasActiveFilters
                  ? const EmptyState(
                      icon: LucideIcons.searchX,
                      title: 'No Results',
                      message: 'No products match your search or filters.',
                    )
                  : EmptyState(
                      icon: LucideIcons.package,
                      title: 'No Products',
                      message: 'Add your first product to get started.',
                      actionLabel: 'Add Product',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AddProductPage()),
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 120),
        itemCount:
            data.items.length + (data.hasMore || data.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= data.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: AppLoadingIndicator()),
            );
          }
          final product = data.items[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(productId: product.id)),
            ),
          );
        },
      ),
    );
  }
}
