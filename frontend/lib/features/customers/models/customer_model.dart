import 'customer_note.dart';
import 'customer_status.dart';
import 'customer_tag.dart';
import 'membership_tier.dart';

/// A single customer profile. Persisted via the backend's Firebase-backed
/// `/customers` endpoint as one JSON blob (see [toJson]/[fromJson]) — field
/// names here are the same friendly, UI-facing shape, so swapping the
/// repository's data source never requires touching this model or any
/// widget that reads it.
class CustomerModel {
  const CustomerModel({
    required this.id,
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
    this.notes = const [],
    this.tags = const [],
    this.status = CustomerStatus.active,
    required this.memberSince,
    this.lifetimeSpend = 0,
    this.totalOrders = 0,
    this.lastPurchaseAt,
    this.loyaltyPoints = 0,
    this.lifetimePoints = 0,
    this.isDeleted = false,
  });

  final String id;
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
  final List<CustomerNote> notes;
  final List<String> tags;
  final CustomerStatus status;
  final DateTime memberSince;

  /// Lifetime totals below are owned entirely by this module — never
  /// derived from Billing/Payments/Receipt, which it must not touch or
  /// integrate with. Real since Phase CRM-1: every customer starts at zero
  /// and is updated exclusively by [CustomerRepositoryImpl.recordPurchase],
  /// called once per completed sale from Billing's payment-success hook.
  final double lifetimeSpend;
  final int totalOrders;
  final DateTime? lastPurchaseAt;
  final int loyaltyPoints;
  final int lifetimePoints;

  /// Soft-delete flag — a deleted customer is hidden from every list by
  /// default but the record itself is never physically removed.
  final bool isDeleted;

  String get fullName => '$firstName $lastName'.trim();

  double get averageOrderValue =>
      totalOrders == 0 ? 0 : lifetimeSpend / totalOrders;

  MembershipTier get membershipTier =>
      MembershipTier.fromLifetimePoints(lifetimePoints);

  bool get isVip => tags.contains(CustomerTags.vip);

  CustomerModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    bool clearEmail = false,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? gender,
    bool clearGender = false,
    String? address,
    bool clearAddress = false,
    String? city,
    bool clearCity = false,
    String? postalCode,
    bool clearPostalCode = false,
    String? country,
    bool clearCountry = false,
    String? company,
    bool clearCompany = false,
    String? vatNumber,
    bool clearVatNumber = false,
    List<CustomerNote>? notes,
    List<String>? tags,
    CustomerStatus? status,
    double? lifetimeSpend,
    int? totalOrders,
    DateTime? lastPurchaseAt,
    int? loyaltyPoints,
    int? lifetimePoints,
    bool? isDeleted,
  }) {
    return CustomerModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: clearEmail ? null : (email ?? this.email),
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      address: clearAddress ? null : (address ?? this.address),
      city: clearCity ? null : (city ?? this.city),
      postalCode: clearPostalCode ? null : (postalCode ?? this.postalCode),
      country: clearCountry ? null : (country ?? this.country),
      company: clearCompany ? null : (company ?? this.company),
      vatNumber: clearVatNumber ? null : (vatNumber ?? this.vatNumber),
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      memberSince: memberSince,
      lifetimeSpend: lifetimeSpend ?? this.lifetimeSpend,
      totalOrders: totalOrders ?? this.totalOrders,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
        'gender': gender,
        'address': address,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'company': company,
        'vatNumber': vatNumber,
        'notes': notes.map((note) => note.toJson()).toList(),
        'tags': tags,
        'status': status.wireValue,
        'memberSince': memberSince.millisecondsSinceEpoch,
        'lifetimeSpend': lifetimeSpend,
        'totalOrders': totalOrders,
        'lastPurchaseAt': lastPurchaseAt?.millisecondsSinceEpoch,
        'loyaltyPoints': loyaltyPoints,
        'lifetimePoints': lifetimePoints,
        'isDeleted': isDeleted,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'] as int),
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      company: json['company'] as String?,
      vatNumber: json['vatNumber'] as String?,
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((note) => CustomerNote.fromJson(note as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      status: CustomerStatus.fromWire(json['status'] as String?),
      memberSince:
          DateTime.fromMillisecondsSinceEpoch(json['memberSince'] as int),
      lifetimeSpend: (json['lifetimeSpend'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      lastPurchaseAt: json['lastPurchaseAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['lastPurchaseAt'] as int),
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      lifetimePoints: (json['lifetimePoints'] as num?)?.toInt() ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
