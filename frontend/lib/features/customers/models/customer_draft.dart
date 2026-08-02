/// The Add/Edit Customer form's validated output — every editable field,
/// in the same friendly shape [CustomerModel] uses. Kept separate from
/// [CustomerModel] (rather than reusing it with placeholder id/timestamps)
/// because a draft has no id/memberSince/lifetime stats yet — those are
/// assigned once, on create, and never re-entered through this form.
class CustomerDraft {
  const CustomerDraft({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.company,
    this.vatNumber,
    this.initialNote,
    this.tags = const [],
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? company;
  final String? vatNumber;

  /// Seeds the customer's first [CustomerNote] on create. Ignored by
  /// [CustomerRepository.updateCustomer] — editing notes goes through
  /// [CustomerRepository.addNote] instead, so an edit never silently drops
  /// notes added since the customer was created.
  final String? initialNote;
  final List<String> tags;
}
