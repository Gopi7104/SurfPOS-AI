/// A product's business-facing lifecycle status — distinct from the
/// backend's `isActive` soft-delete flag (a soft-deleted product never
/// appears in listings at all; `INACTIVE` is a merchant choice to hide a
/// product from sale without deleting it).
enum ProductStatus {
  active,
  inactive;

  static ProductStatus fromWire(String? value) => switch (value) {
        'INACTIVE' => ProductStatus.inactive,
        _ => ProductStatus.active,
      };

  String get wireValue => switch (this) {
        ProductStatus.active => 'ACTIVE',
        ProductStatus.inactive => 'INACTIVE',
      };

  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.inactive => 'Inactive',
      };
}
