import '../models/inventory_query.dart';
import '../models/product_model.dart';

/// [InventoryListController]'s state — the currently loaded page(s) of
/// products plus the search/filter/sort query that produced them.
/// [isLoadingMore] is tracked separately from the notifier's own
/// `AsyncValue` wrapper so an infinite-scroll fetch never hides the
/// already-loaded list behind a full loading state.
class InventoryListState {
  const InventoryListState({
    required this.items,
    required this.query,
    required this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<ProductModel> items;
  final InventoryQuery query;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  InventoryListState copyWith({
    List<ProductModel>? items,
    InventoryQuery? query,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return InventoryListState(
      items: items ?? this.items,
      query: query ?? this.query,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
