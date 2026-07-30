import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/api_exception.dart';
import '../data/datasources/firebase_auth_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';

/// User-facing failure message for any auth operation. Never surfaces raw
/// exception types/stack traces to the UI — [message] is always safe to
/// show directly (see docs/07_CODING_RULES.md § 14, and the task's explicit
/// friendly-error-message requirements).
class AuthFailure {
  const AuthFailure(this.message);

  final String message;

  /// Maps every exception this feature's data layer can throw to a single
  /// friendly message. Backend [ApiException] messages are already
  /// human-readable (relayed verbatim); Firebase/Google errors are not, so
  /// those get authored copy here.
  factory AuthFailure.fromException(Object error) {
    if (error is GoogleSignInCancelled) {
      return const AuthFailure('Google sign-in was cancelled.');
    }
    if (error is GoogleAccountNotRegistered) {
      return const AuthFailure(
        "This Google account isn't registered yet — please create an account "
        'with email and password first.',
      );
    }
    if (error is FirebaseAuthException) {
      return AuthFailure(_fromFirebaseAuthException(error));
    }
    if (error is ApiException) {
      return AuthFailure(error.message);
    }
    return const AuthFailure('Something went wrong. Please try again.');
  }

  static String _fromFirebaseAuthException(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'invalid-credential' ||
      'wrong-password' =>
        'Incorrect email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Choose a stronger password.',
      'account-exists-with-different-credential' =>
        'An account already exists with this email using a different sign-in method.',
      'network-request-failed' =>
        'Could not reach the server. Check your internet connection and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
