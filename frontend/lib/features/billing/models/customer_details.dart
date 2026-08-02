/// Optional walk-in-customer info captured right before Checkout — both
/// fields are always optional and this is never persisted or sent to any
/// backend; it only rides along in-memory to the eventual [ReceiptModel]
/// so the Receipt can show who the sale was for. A later phase may turn
/// [phone] into a lookup key (digital/WhatsApp/SMS receipts, purchase
/// history, loyalty) — this value object deliberately carries nothing more
/// than what today's UI needs.
class CustomerDetails {
  const CustomerDetails({this.name, this.phone});

  final String? name;
  final String? phone;

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      (phone == null || phone!.trim().isEmpty);

  CustomerDetails copyWith({String? name, String? phone}) {
    return CustomerDetails(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
