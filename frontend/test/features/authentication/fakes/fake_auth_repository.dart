import 'package:surfpos_ai/features/authentication/data/models/auth_user.dart';
import 'package:surfpos_ai/features/authentication/data/repositories/auth_repository.dart';

/// Configurable [AuthRepository] test double — every method defaults to a
/// no-op/empty-session behavior, and can be overridden per test via the
/// constructor to exercise a specific success or failure path without ever
/// touching real Firebase or network calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Future<AuthUser?> Function()? restoreSession,
    Future<AuthUser> Function({
      required String fullName,
      required String email,
      required String password,
      String? mobileNumber,
    })? signUp,
    Future<AuthUser> Function(
            {required String email, required String password})?
        logIn,
    Future<AuthUser> Function()? logInWithGoogle,
    Future<void> Function(String email)? sendPasswordResetEmail,
    Future<void> Function()? logOut,
  })  : _restoreSession = restoreSession ?? (() async => null),
        _signUp = signUp,
        _logIn = logIn,
        _logInWithGoogle = logInWithGoogle,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        _logOut = logOut ?? (() async {});

  final Future<AuthUser?> Function() _restoreSession;
  final Future<AuthUser> Function({
    required String fullName,
    required String email,
    required String password,
    String? mobileNumber,
  })? _signUp;
  final Future<AuthUser> Function(
      {required String email, required String password})? _logIn;
  final Future<AuthUser> Function()? _logInWithGoogle;
  final Future<void> Function(String email)? _sendPasswordResetEmail;
  final Future<void> Function() _logOut;

  @override
  Future<AuthUser?> restoreSession() => _restoreSession();

  @override
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
    String? mobileNumber,
  }) {
    final signUp = _signUp;
    if (signUp == null) throw UnimplementedError();
    return signUp(
      fullName: fullName,
      email: email,
      password: password,
      mobileNumber: mobileNumber,
    );
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    final logIn = _logIn;
    if (logIn == null) throw UnimplementedError();
    return logIn(email: email, password: password);
  }

  @override
  Future<AuthUser> logInWithGoogle() {
    final logInWithGoogle = _logInWithGoogle;
    if (logInWithGoogle == null) throw UnimplementedError();
    return logInWithGoogle();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    final sendPasswordResetEmail = _sendPasswordResetEmail;
    if (sendPasswordResetEmail == null) throw UnimplementedError();
    return sendPasswordResetEmail(email);
  }

  @override
  Future<void> logOut() => _logOut();
}

AuthUser testAuthUser(
    {String uid = 'uid-1', String email = 'owner@surfpos.se'}) {
  final now = DateTime.utc(2026, 1, 1);
  return AuthUser(
    uid: uid,
    email: email,
    displayName: 'Jane Doe',
    role: 'owner',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}
