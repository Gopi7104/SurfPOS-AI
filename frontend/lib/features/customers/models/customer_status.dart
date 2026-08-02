/// A customer's lifecycle flag — distinct from soft-delete
/// ([CustomerModel.isDeleted]): an inactive customer is still a real,
/// visible record a merchant can reactivate, whereas a deleted one is
/// hidden from every list by default.
enum CustomerStatus {
  active,
  inactive;

  String get label => switch (this) {
        CustomerStatus.active => 'Active',
        CustomerStatus.inactive => 'Inactive',
      };

  String get wireValue => switch (this) {
        CustomerStatus.active => 'ACTIVE',
        CustomerStatus.inactive => 'INACTIVE',
      };

  static CustomerStatus fromWire(String? value) =>
      value == 'INACTIVE' ? CustomerStatus.inactive : CustomerStatus.active;
}
