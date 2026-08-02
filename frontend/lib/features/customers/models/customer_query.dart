/// Customer List's filter chip — combines the spec's "Filters" list with
/// two chips that are really sort orders (Recently Added/Highest Spending)
/// rather than a predicate, same simplification `InventoryQuery` doesn't
/// need but keeps this list short and chip-driven per the brief.
enum CustomerFilter {
  all,
  active,
  inactive,
  vip,
  recentlyAdded,
  highestSpending;

  String get label => switch (this) {
        CustomerFilter.all => 'All Customers',
        CustomerFilter.active => 'Active',
        CustomerFilter.inactive => 'Inactive',
        CustomerFilter.vip => 'VIP',
        CustomerFilter.recentlyAdded => 'Recently Added',
        CustomerFilter.highestSpending => 'Highest Spending',
      };
}

/// Everything [CustomerRepository.listCustomers] accepts, in one immutable
/// value — mirrors `InventoryQuery`'s role for [InventoryListController].
class CustomerQuery {
  const CustomerQuery({this.search, this.filter = CustomerFilter.all});

  /// Matched against name, phone, email, and customer id (see
  /// [CustomerRepositoryImpl.listCustomers]).
  final String? search;
  final CustomerFilter filter;

  CustomerQuery copyWith({
    String? search,
    bool clearSearch = false,
    CustomerFilter? filter,
  }) {
    return CustomerQuery(
      search: clearSearch ? null : (search ?? this.search),
      filter: filter ?? this.filter,
    );
  }

  bool get hasActiveFilters =>
      (search != null && search!.isNotEmpty) || filter != CustomerFilter.all;
}
