import '../models/auth_user.dart';

/// Seam between the Riverpod controller and the actual data sources — lets
/// `AuthController` be unit-tested against a fake, without touching real
/// Firebase/network/storage (see docs/07_CODING_RULES.md § 3).
abstract class AuthRepository {
  /// Restores a previously-persisted session, if any. Returns `null` if
  /// there is no session to restore.
  Future<AuthUser?> restoreSession();

  /// Registers a new account (backend) then establishes a client-side
  /// Firebase session with the same credentials, so the caller ends up
  /// fully signed in. [mobileNumber] is intentionally accepted but never
  /// forwarded anywhere — see the class doc on the implementation.
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
    String? mobileNumber,
  });

  Future<AuthUser> logIn({required String email, required String password});

  /// Signs in with Google. Throws [GoogleSignInCancelled] if the user
  /// dismissed the account picker.
  Future<AuthUser> logInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> logOut();
}
