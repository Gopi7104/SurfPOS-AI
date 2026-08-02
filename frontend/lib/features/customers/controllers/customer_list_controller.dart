import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_query.dart';
import '../providers/customer_providers.dart';
import 'customer_list_state.dart';

export 'customer_list_state.dart';

const _pageSize = 20;

/// Customer-list state for exactly one Firebase uid (see
/// [customerListControllerProvider] — a `.family` provider, the uid is
/// this notifier's `arg`) — never a global singleton, mirrors
/// `InventoryListController` exactly, including its infinite-scroll and
/// optimistic-delete shape.
class CustomerListController
    extends AutoDisposeFamilyAsyncNotifier<CustomerListState, String> {
  @override
  Future<CustomerListState> build(String uid) {
    return _fetchFirstPage(uid, const CustomerQuery());
  }

  Future<CustomerListState> _fetchFirstPage(
      String uid, CustomerQuery query) async {
    final page = await ref
        .read(customerRepositoryProvider(uid))
        .listCustomers(query, limit: _pageSize);
    return CustomerListState(
        items: page.items, query: query, nextCursor: page.nextCursor);
  }

  /// Applies a new search/filter query, replacing the current list.
  Future<void> applyQuery(CustomerQuery query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFirstPage(arg, query));
  }

  /// Pull-to-refresh — reloads the first page with the current query.
  Future<void> refresh() async {
    final query = state.valueOrNull?.query ?? const CustomerQuery();
    state = await AsyncValue.guard(() => _fetchFirstPage(arg, query));
  }

  /// Infinite-scroll: appends the next page, if any. A no-op while a load
  /// is already in flight, or there is no further page.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(customerRepositoryProvider(arg))
          .listCustomers(current.query,
              cursor: current.nextCursor, limit: _pageSize);
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
      // not-loading and rethrow so the caller can show a one-off retry affordance instead of
      // replacing the whole screen with an error state, mirroring `InventoryListController`.
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Soft-deletes a customer and removes it from the currently loaded list
  /// — optimistic UI: the caller doesn't wait for a full refetch to see it
  /// disappear.
  Future<void> deleteCustomer(String customerId) async {
    await ref.read(customerRepositoryProvider(arg)).deleteCustomer(customerId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
          items: current.items.where((c) => c.id != customerId).toList()),
    );
  }
}
