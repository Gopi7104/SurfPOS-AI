import '../models/customer_model.dart';
import '../models/customer_query.dart';

/// [CustomerListController]'s state — mirrors `InventoryListState` exactly:
/// the currently loaded page(s) plus the query that produced them, with
/// [isLoadingMore] tracked separately so an infinite-scroll fetch never
/// hides the already-loaded list behind a full loading state.
class CustomerListState {
  const CustomerListState({
    required this.items,
    required this.query,
    required this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<CustomerModel> items;
  final CustomerQuery query;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  CustomerListState copyWith({
    List<CustomerModel>? items,
    CustomerQuery? query,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return CustomerListState(
      items: items ?? this.items,
      query: query ?? this.query,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
