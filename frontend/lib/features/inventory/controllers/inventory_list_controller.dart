import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_query.dart';
import '../providers/inventory_providers.dart';
import 'inventory_list_state.dart';

export 'inventory_list_state.dart';

const _pageSize = 20;

/// Product-list state for exactly one Firebase uid (see
/// [inventoryListControllerProvider] — a `.family` provider, the uid is
/// this notifier's `arg`) — never a global singleton, so one merchant's
/// catalog can never be observed under another account's session, even
/// transiently (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user isolation
/// fix).
class InventoryListController
    extends AutoDisposeFamilyAsyncNotifier<InventoryListState, String> {
  @override
  Future<InventoryListState> build(String uid) {
    return _fetchFirstPage(const InventoryQuery());
  }

  Future<InventoryListState> _fetchFirstPage(InventoryQuery query) async {
    final page = await ref
        .read(inventoryRepositoryProvider)
        .listProducts(query, limit: _pageSize);
    return InventoryListState(
        items: page.items, query: query, nextCursor: page.nextCursor);
  }

  /// Applies a new search/filter/sort query, replacing the current list.
  Future<void> applyQuery(InventoryQuery query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFirstPage(query));
  }

  /// Pull-to-refresh — reloads the first page with the current query.
  Future<void> refresh() async {
    final query = state.valueOrNull?.query ?? const InventoryQuery();
    state = await AsyncValue.guard(() => _fetchFirstPage(query));
  }

  /// Infinite-scroll: appends the next page, if any. A no-op while a load
  /// is already in flight, or there is no further page.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref.read(inventoryRepositoryProvider).listProducts(
            current.query,
            cursor: current.nextCursor,
            limit: _pageSize,
          );
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      // A failed "load more" shouldn't blow away the already-loaded list — drop back to
      // not-loading and rethrow so the caller can show a one-off retry affordance (e.g. a
      // snackbar) instead of replacing the whole screen with an error state.
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Soft-deletes a product and removes it from the currently loaded list —
  /// avoids waiting for a full refetch just to reflect a delete the caller
  /// already knows succeeded.
  Future<void> deleteProduct(String productId) async {
    await ref.read(inventoryRepositoryProvider).deleteProduct(productId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
          items: current.items
              .where((product) => product.id != productId)
              .toList()),
    );
  }
}
