/// Stock-level filter chip — maps to the backend's `stockFilter` query
/// param (`backend/src/modules/inventory/inventory.service.js`).
enum StockFilter {
  all,
  lowStock,
  inStock,
  outOfStock;

  String? get wireValue => switch (this) {
        StockFilter.all => null,
        StockFilter.lowStock => 'lowStock',
        StockFilter.inStock => 'inStock',
        StockFilter.outOfStock => 'outOfStock',
      };

  String get label => switch (this) {
        StockFilter.all => 'All',
        StockFilter.lowStock => 'Low Stock',
        StockFilter.inStock => 'In Stock',
        StockFilter.outOfStock => 'Out of Stock',
      };
}

/// Sort option shown in the Product List's sort menu — each maps to a
/// `(sortBy, sortOrder)` pair on the backend's `GET /inventory/products`
/// query. "Newest"/"Oldest" (from the Filters spec) and "Alphabetical" /
/// "Price" / "Stock" / "Recently Updated" (from the Sorting spec) are both
/// represented here since they're the same underlying mechanism.
enum InventorySortOption {
  alphabetical,
  priceLowToHigh,
  priceHighToLow,
  stockLowToHigh,
  stockHighToLow,
  recentlyUpdated,
  newest,
  oldest;

  String get label => switch (this) {
        InventorySortOption.alphabetical => 'Alphabetical',
        InventorySortOption.priceLowToHigh => 'Price: Low to High',
        InventorySortOption.priceHighToLow => 'Price: High to Low',
        InventorySortOption.stockLowToHigh => 'Stock: Low to High',
        InventorySortOption.stockHighToLow => 'Stock: High to Low',
        InventorySortOption.recentlyUpdated => 'Recently Updated',
        InventorySortOption.newest => 'Newest',
        InventorySortOption.oldest => 'Oldest',
      };

  String get sortBy => switch (this) {
        InventorySortOption.alphabetical => 'name',
        InventorySortOption.priceLowToHigh ||
        InventorySortOption.priceHighToLow =>
          'price',
        InventorySortOption.stockLowToHigh ||
        InventorySortOption.stockHighToLow =>
          'stock',
        InventorySortOption.recentlyUpdated => 'updatedAt',
        InventorySortOption.newest || InventorySortOption.oldest => 'createdAt',
      };

  String get sortOrder => switch (this) {
        InventorySortOption.alphabetical => 'asc',
        InventorySortOption.priceLowToHigh => 'asc',
        InventorySortOption.priceHighToLow => 'desc',
        InventorySortOption.stockLowToHigh => 'asc',
        InventorySortOption.stockHighToLow => 'desc',
        InventorySortOption.recentlyUpdated => 'desc',
        InventorySortOption.newest => 'desc',
        InventorySortOption.oldest => 'asc',
      };
}

/// Everything `GET /inventory/products` accepts, in one immutable value —
/// [InventoryListController] holds one of these as its current
/// search/filter/sort state and rebuilds the query string from it on every
/// page fetch.
class InventoryQuery {
  const InventoryQuery({
    this.search,
    this.barcode,
    this.category,
    this.status,
    this.stockFilter = StockFilter.all,
    this.sortOption,
  });

  final String? search;

  /// Exact-match barcode lookup — distinct from [search] (a fuzzy substring
  /// match across name/SKU/barcode). Used by Billing's barcode-scan flow,
  /// where a decoded code must resolve to exactly one product, not fuzzy-
  /// match several (see docs/22_DEVELOPMENT_ROADMAP.md, Phase 3 Billing).
  /// Maps to the same backend `barcode` query param
  /// `product.repository.js#applyFilters` already supports.
  final String? barcode;
  final String? category;
  final ProductStatusFilter? status;
  final StockFilter stockFilter;
  final InventorySortOption? sortOption;

  InventoryQuery copyWith({
    String? search,
    bool clearSearch = false,
    String? barcode,
    bool clearBarcode = false,
    String? category,
    bool clearCategory = false,
    ProductStatusFilter? status,
    bool clearStatus = false,
    StockFilter? stockFilter,
    InventorySortOption? sortOption,
    bool clearSortOption = false,
  }) {
    return InventoryQuery(
      search: clearSearch ? null : (search ?? this.search),
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      stockFilter: stockFilter ?? this.stockFilter,
      sortOption: clearSortOption ? null : (sortOption ?? this.sortOption),
    );
  }

  Map<String, dynamic> toQueryParameters({int limit = 20, String? cursor}) {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (category != null) 'category': category,
      if (status != null) 'status': status!.wireValue,
      if (stockFilter.wireValue != null) 'stockFilter': stockFilter.wireValue,
      if (sortOption != null) 'sortBy': sortOption!.sortBy,
      if (sortOption != null) 'sortOrder': sortOption!.sortOrder,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
  }

  bool get hasActiveFilters =>
      (search != null && search!.isNotEmpty) ||
      (barcode != null && barcode!.isNotEmpty) ||
      category != null ||
      status != null ||
      stockFilter != StockFilter.all;
}

/// The "Status" filter chip — deliberately distinct from [ProductStatus]
/// (the model's own enum) so `all` can be represented without a nullable
/// `ProductStatus?` sprinkled through the filter UI.
enum ProductStatusFilter {
  active,
  inactive;

  String get wireValue => switch (this) {
        ProductStatusFilter.active => 'ACTIVE',
        ProductStatusFilter.inactive => 'INACTIVE',
      };

  String get label => switch (this) {
        ProductStatusFilter.active => 'Active',
        ProductStatusFilter.inactive => 'Inactive',
      };
}
