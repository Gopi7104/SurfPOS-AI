/// Optional walk-in-customer info captured right before Checkout — `name`/
/// `phone` are always optional and never persisted or sent to any backend
/// on their own; they only ride along in-memory to the eventual
/// [ReceiptModel] so the Receipt can show who the sale was for.
///
/// [customerId], added in Phase CRM-1, is the one field that IS a real
/// lookup key: set only when the cashier's typed phone number matched (or
/// was used to create) a real record in `features/customers`' own
/// `CustomerRepository` — see `showCustomerDetailsSheet`. `null` means
/// exactly what it always meant before this phase: a plain walk-in name/
/// phone with no linked customer record, still fully supported (this step
/// stays entirely optional/skippable either way).
class CustomerDetails {
  const CustomerDetails({this.name, this.phone, this.customerId});

  final String? name;
  final String? phone;
  final String? customerId;

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      (phone == null || phone!.trim().isEmpty);

  CustomerDetails copyWith({String? name, String? phone, String? customerId}) {
    return CustomerDetails(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      customerId: customerId ?? this.customerId,
    );
  }
}
