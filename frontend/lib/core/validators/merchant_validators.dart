/// Client-side form validators for the Merchant Onboarding wizard —
/// feedback-only, never the source of truth (see docs/07_CODING_RULES.md §
/// 10). Rules mirror `backend/src/validators/merchantApplication.validation.js`
/// exactly, which in turn mirrors the confirmed Surfboard Create Merchant
/// API (see docs/08_ARCHITECTURE_DECISIONS.md § ADR-026) — do not add rules
/// beyond what Surfboard actually requires (e.g. no GST/PAN/IFSC-style
/// validation; those fields don't exist in the real API).
library;

final _countryCodePattern = RegExp(r'^[A-Za-z]{2}$');
final _mccCodePattern = RegExp(r'^\d{4}$');
final _phoneCodePattern = RegExp(r'^\d{1,4}$');
final _phoneNumberPattern = RegExp(r'^\d{5,15}$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateRequired(String value, String fieldLabel) {
  if (value.trim().isEmpty) return '$fieldLabel is required';
  return null;
}

String? validateCorporateId(String value) =>
    validateRequired(value, 'Corporate ID');

String? validateCountryCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Country is required';
  if (!_countryCodePattern.hasMatch(trimmed)) {
    return 'Enter a 2-letter country code (e.g. SE)';
  }
  return null;
}

/// Merchant Category Code — optional on the wire (Surfboard only requires it
/// for PF partners), so an empty value is valid; only validated for shape
/// when the merchant chooses to provide one.
String? validateMccCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!_mccCodePattern.hasMatch(trimmed)) {
    return 'Enter a 4-digit Merchant Category Code';
  }
  return null;
}

String? validateEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Email is required';
  if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
  return null;
}

String? validatePhoneCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Country calling code is required';
  if (!_phoneCodePattern.hasMatch(trimmed)) {
    return 'Digits only, no + (e.g. 46)';
  }
  return null;
}

String? validatePhoneNumber(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Phone number is required';
  if (!_phoneNumberPattern.hasMatch(trimmed)) return 'Enter 5-15 digits';
  return null;
}

String? validateAddressLine1(String value) =>
    validateRequired(value, 'Address');

String? validateCity(String value) => validateRequired(value, 'City');

String? validatePostalCode(String value) =>
    validateRequired(value, 'Postal code');

String? validateStoreName(String value) =>
    validateRequired(value, 'Store name');
