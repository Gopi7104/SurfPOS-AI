import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/shell_navigation_providers.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_fab.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../../core/widgets/text_fields/app_search_field.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../merchant/presentation/screens/merchant_onboarding_wizard_page.dart';
import '../controllers/inventory_list_state.dart';
import '../models/inventory_query.dart';
import '../models/product_model.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_category_chip_bar.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/inventory_hero_card.dart';
import '../widgets/inventory_quick_filter_bar.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_quick_actions_sheet.dart';
import 'add_product_entry_page.dart';
import 'categories_page.dart';
import 'product_details_page.dart';

enum _ViewMode { grid, list }

/// The Inventory tab's unified Home — hero stats, instant search, sticky
/// category chips, quick filters, a pinned Low Stock section, and a
/// switchable grid/list of the catalog (see the Phase UI/UX 4 redesign
/// brief). Supersedes the old split Home/Product-List pair: this **is**
/// the product list now, not just a summary+quick-actions landing page.
class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({this.initialCategory, super.key});

  /// Pre-applies a category filter — used when arriving from
  /// [CategoriesPage]. Applied to the same shared
  /// `inventoryListControllerProvider(uid)` the tab-root instance of this
  /// page already reads, so returning to that instance reflects the filter
  /// too (same behavior the old `ProductListPage(initialCategory:)` had).
  final String? initialCategory;

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  /// Remembered for the lifetime of this widget (kept mounted by the app
  /// shell's `IndexedStack`, so this survives switching tabs) — not
  /// persisted to disk; `shared_preferences` isn't a dependency of this app
  /// today and adding one is out of scope for a UI-only phase.
  _ViewMode _viewMode = _ViewMode.grid;

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
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final current =
          ref.read(inventoryListControllerProvider(uid)).valueOrNull?.query ??
              const InventoryQuery();
      ref.read(inventoryListControllerProvider(uid).notifier).applyQuery(
          current.copyWith(search: value, clearSearch: value.isEmpty));
    });
  }

  void _onCategorySelected(String uid, String? category) {
    final current =
        ref.read(inventoryListControllerProvider(uid)).valueOrNull?.query ??
            const InventoryQuery();
    ref.read(inventoryListControllerProvider(uid).notifier).applyQuery(
          category == null
              ? current.copyWith(clearCategory: true)
              : current.copyWith(category: category),
        );
  }

  void _openProduct(String productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ProductDetailsPage(productId: productId)),
    );
  }

  void _openQuickActions(String uid, ProductModel product) {
    showProductQuickActionsSheet(context, uid: uid, product: product);
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // SurfAI's chat page sets this to prefill a search (e.g. "search Coca
    // Cola") even though this page is already mounted (kept alive by the
    // shell's IndexedStack) — see shell_navigation_providers.dart's header
    // comment. Syncs both the visible field and the shared query state.
    ref.listen(pendingInventorySearchProvider, (previous, next) {
      if (next != null) {
        _searchController.text = next;
        _onSearchChanged(next, uid);
        ref.read(pendingInventorySearchProvider.notifier).state = null;
      }
    });

    final provider = inventoryListControllerProvider(uid);
    final state = ref.watch(provider);
    final categories =
        ref.watch(inventoryCategoriesProvider(uid)).valueOrNull ??
            const <String>[];

    final notOnboarded = state.hasError && state.error is NotFoundApiException;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Inventory',
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(LucideIcons.tag),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            ),
          ),
          IconButton(
            tooltip: _viewMode == _ViewMode.grid ? 'List view' : 'Grid view',
            icon: Icon(_viewMode == _ViewMode.grid
                ? LucideIcons.list
                : LucideIcons.layoutGrid),
            onPressed: () => setState(() {
              _viewMode =
                  _viewMode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid;
            }),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        icon: Icons.add_rounded,
        label: 'Add Product',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddProductEntryPage()),
        ),
      ),
      body: notOnboarded
          ? _OnboardingPrompt(
              onRefresh: () => ref.invalidate(provider),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(provider),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.md, AppSpacing.md, AppSpacing.md),
                      child: switch (state) {
                        AsyncLoading() when !state.hasValue =>
                          const InventoryHeroCard(
                              items: [], isApproximate: false),
                        _ => InventoryHeroCard(
                            items: state.valueOrNull?.items ?? const [],
                            isApproximate: state.valueOrNull?.hasMore ?? false,
                          ),
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppSearchField(
                        hint: 'Search by name, SKU, or barcode',
                        controller: _searchController,
                        onChanged: (value) => _onSearchChanged(value, uid),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyRowDelegate(
                      height: 40,
                      child: InventoryCategoryChipBar(
                        categories: categories,
                        selectedCategory: state.valueOrNull?.query.category,
                        onSelected: (category) =>
                            _onCategorySelected(uid, category),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                      child: InventoryQuickFilterBar(
                        query:
                            state.valueOrNull?.query ?? const InventoryQuery(),
                        onQueryChanged: (query) =>
                            ref.read(provider.notifier).applyQuery(query),
                      ),
                    ),
                  ),
                  if ((state.valueOrNull?.items ?? const <ProductModel>[])
                      .isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                        child: LowStockSection(
                            uid: uid, items: state.valueOrNull!.items),
                      ),
                    ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm)),
                  ..._buildBody(context, uid, state),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildBody(
      BuildContext context, String uid, AsyncValue<InventoryListState> state) {
    if (state is AsyncLoading && !state.hasValue) {
      return const [
        SliverFillRemaining(
            hasScrollBody: false, child: Center(child: AppLoadingIndicator()))
      ];
    }
    if (state is AsyncError && !state.hasValue) {
      final provider = inventoryListControllerProvider(uid);
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            message:
                'Could not load your products. Please check your connection and try again.',
            onRetry: () => ref.read(provider.notifier).refresh(),
          ),
        ),
      ];
    }

    final data = state.value!;
    if (data.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: data.query.hasActiveFilters
              ? const InventoryEmptyState(
                  icon: LucideIcons.searchX,
                  title: 'No Search Results',
                  message: 'No products match your search or filters.',
                )
              : InventoryEmptyState(
                  icon: LucideIcons.package,
                  title: 'No Products',
                  message: 'Add your first product to get started.',
                  actionLabel: 'Add Product',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AddProductEntryPage()),
                  ),
                ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _viewMode == _ViewMode.grid
              ? _buildGrid(context, uid, data)
              : _buildList(context, uid, data),
        ),
      ),
      if (data.isLoadingMore)
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          sliver:
              SliverToBoxAdapter(child: Center(child: AppLoadingIndicator())),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
    ];
  }

  Widget _buildGrid(BuildContext context, String uid, InventoryListState data) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = (width / 170).floor().clamp(2, 6);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.68,
      ),
      itemCount: data.items.length,
      itemBuilder: (context, index) {
        final product = data.items[index];
        return ProductGridCard(
          product: product,
          onTap: () => _openProduct(product.id),
          onLongPress: () => _openQuickActions(uid, product),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, String uid, InventoryListState data) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = data.items[index];
        return ProductCard(
          product: product,
          onTap: () => _openProduct(product.id),
          onLongPress: () => _openQuickActions(uid, product),
        );
      },
    );
  }
}

class _OnboardingPrompt extends StatelessWidget {
  const _OnboardingPrompt({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: InventoryEmptyState(
              icon: LucideIcons.building2,
              title: 'Complete Merchant Onboarding',
              message:
                  'Submit your merchant application to start managing inventory.',
              actionLabel: 'Start Onboarding',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MerchantOnboardingWizardPage()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pins [child] at a fixed [height] inside a `CustomScrollView` — used for
/// the category chip row so it stays put ("sticky while scrolling") while
/// everything above it (hero, search) scrolls away.
class _StickyRowDelegate extends SliverPersistentHeaderDelegate {
  const _StickyRowDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: AppColors.background, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyRowDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
