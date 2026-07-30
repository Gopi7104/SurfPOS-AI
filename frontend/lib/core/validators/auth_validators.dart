/// Client-side form validators for authentication screens — feedback-only,
/// never the source of truth (see docs/07_CODING_RULES.md § 10). The
/// backend's own `POST /auth/signup` schema only requires a minimum of 8
/// characters (see `backend/src/validators/auth.validation.js`); the
/// complexity rules below (upper/lower/number/special-char) are a stricter
/// client-side UX choice on top of that, not something the backend enforces
/// or needs changed to match — do not "relax" this to mirror the backend.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _uppercasePattern = RegExp(r'[A-Z]');
final _lowercasePattern = RegExp(r'[a-z]');
final _digitPattern = RegExp(r'\d');
final _specialCharPattern =
    RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\];\x27~`/\\]');

/// Returns an error message, or `null` if [value] is a valid email.
String? validateEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Email is required';
  if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
  return null;
}

/// Login only needs a non-empty password — complexity was already enforced
/// (or not) at signup; re-validating it here would just block existing users.
String? validateLoginPassword(String value) {
  if (value.isEmpty) return 'Password is required';
  return null;
}

/// Full complexity check, used at signup only.
String? validateSignupPassword(String value) {
  if (value.isEmpty) return 'Password is required';
  if (value.length < 8) return 'Password must be at least 8 characters';
  if (!_uppercasePattern.hasMatch(value)) {
    return 'Password must include an uppercase letter';
  }
  if (!_lowercasePattern.hasMatch(value)) {
    return 'Password must include a lowercase letter';
  }
  if (!_digitPattern.hasMatch(value)) return 'Password must include a number';
  if (!_specialCharPattern.hasMatch(value)) {
    return 'Password must include a special character';
  }
  return null;
}

String? validateConfirmPassword(String password, String confirmPassword) {
  if (confirmPassword.isEmpty) return 'Confirm your password';
  if (confirmPassword != password) return 'Passwords do not match';
  return null;
}

String? validateFullName(String value) {
  if (value.trim().isEmpty) return 'Full name is required';
  return null;
}
