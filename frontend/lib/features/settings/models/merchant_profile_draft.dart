/// The Merchant Profile section's editable fields — deliberately a **local**
/// override, not a write to Surfboard. This app has no reachable, permitted
/// endpoint to update a live Surfboard merchant profile from (that would
/// mean touching the Surfboard integration/backend, out of scope for
/// Settings), so editing here never changes what Dashboard reads from
/// `GET /merchant`. Fields left blank fall back to whatever Dashboard's own
/// live Surfboard-sourced [MerchantProfileModel] shows, so this never hides
/// real data — it only lets a merchant annotate/correct things Surfboard
/// doesn't carry at all (Logo, Business Type) or override display-only
/// copies of things it does.
class MerchantProfileDraft {
  const MerchantProfileDraft({
    this.businessName,
    this.contactEmail,
    this.phone,
    this.logoPath,
    this.address,
    this.country,
    this.taxNumber,
    this.businessType,
  });

  final String? businessName;
  final String? contactEmail;
  final String? phone;
  final String? logoPath;
  final String? address;
  final String? country;
  final String? taxNumber;
  final String? businessType;

  MerchantProfileDraft copyWith({
    String? businessName,
    String? contactEmail,
    String? phone,
    String? logoPath,
    String? address,
    String? country,
    String? taxNumber,
    String? businessType,
  }) {
    return MerchantProfileDraft(
      businessName: businessName ?? this.businessName,
      contactEmail: contactEmail ?? this.contactEmail,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
      address: address ?? this.address,
      country: country ?? this.country,
      taxNumber: taxNumber ?? this.taxNumber,
      businessType: businessType ?? this.businessType,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'contactEmail': contactEmail,
        'phone': phone,
        'logoPath': logoPath,
        'address': address,
        'country': country,
        'taxNumber': taxNumber,
        'businessType': businessType,
      };

  factory MerchantProfileDraft.fromJson(Map<String, dynamic> json) {
    return MerchantProfileDraft(
      businessName: json['businessName'] as String?,
      contactEmail: json['contactEmail'] as String?,
      phone: json['phone'] as String?,
      logoPath: json['logoPath'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      taxNumber: json['taxNumber'] as String?,
      businessType: json['businessType'] as String?,
    );
  }
}
