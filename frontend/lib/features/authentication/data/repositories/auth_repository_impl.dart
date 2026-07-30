import '../../../../core/exceptions/api_exception.dart';
import '../datasources/auth_api_service.dart';
import '../datasources/auth_local_storage.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

/// Thrown when a Google sign-in succeeds but the backend still has no
/// `users/{uid}` profile for that account (`404 USER_PROFILE_NOT_FOUND`).
/// `POST /auth/login` now auto-provisions a profile for any federated
/// (non-password) sign-in with no existing profile — by uid or by a
/// previously-registered email — so this should no longer trigger in
/// practice; kept as a defensive fallback for a genuinely unexpected backend
/// response (see auth.service.js#login).
class GoogleAccountNotRegistered implements Exception {
  const GoogleAccountNotRegistered();
}

/// Owns all cross-data-source orchestration for auth — the only place that
/// knows, for example, that a signup must be followed by a client-side
/// sign-in, or that a Google `USER_PROFILE_NOT_FOUND` means "sign back out."
/// `AuthController` talks only to the [AuthRepository] interface.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource firebaseAuthDataSource,
    required AuthApiService authApiService,
    required AuthLocalStorage authLocalStorage,
  })  : _firebaseAuthDataSource = firebaseAuthDataSource,
        _authApiService = authApiService,
        _authLocalStorage = authLocalStorage;

  final FirebaseAuthDataSource _firebaseAuthDataSource;
  final AuthApiService _authApiService;
  final AuthLocalStorage _authLocalStorage;

  @override
  Future<AuthUser?> restoreSession() async {
    if (_firebaseAuthDataSource.currentUser == null) {
      await _authLocalStorage.clear();
      return null;
    }

    try {
      final user = await _authApiService.me();
      await _authLocalStorage.cacheUser(user);
      await _authLocalStorage.setLoggedIn(true);
      return user;
    } on ApiException {
      // Firebase thinks there's a session but the backend disagrees (token
      // expired beyond refresh, profile deleted, backend unreachable) — fall
      // back to whatever was last cached rather than forcing a hard logout
      // on a transient network blip.
      final cached = await _authLocalStorage.readCachedUser();
      if (cached != null && await _authLocalStorage.isLoggedIn()) {
        return cached;
      }
      return null;
    }
  }

  @override
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
    String? mobileNumber,
  }) async {
    // mobileNumber is deliberately unused: backend's signUpSchema has no
    // phone field yet (see backend/src/validators/auth.validation.js) — the
    // UI still captures it so the form matches the design brief, but nothing
    // is sent. Flagged in the Final Report as a known gap.
    final user = await _authApiService.signup(
      email: email,
      password: password,
      displayName: fullName,
    );

    // /auth/signup creates the Firebase account server-side only — the
    // client has no live Firebase session yet, so sign in with the same
    // credentials to establish one.
    await _firebaseAuthDataSource.signInWithEmail(
        email: email, password: password);

    await _authLocalStorage.cacheUser(user);
    await _authLocalStorage.setLoggedIn(true);
    return user;
  }

  @override
  Future<AuthUser> logIn(
      {required String email, required String password}) async {
    final idToken = await _firebaseAuthDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    final user = await _authApiService.login(idToken);
    await _authLocalStorage.cacheUser(user);
    await _authLocalStorage.setLoggedIn(true);
    return user;
  }

  @override
  Future<AuthUser> logInWithGoogle() async {
    final idToken = await _firebaseAuthDataSource.signInWithGoogle();

    try {
      final user = await _authApiService.login(idToken);
      await _authLocalStorage.cacheUser(user);
      await _authLocalStorage.setLoggedIn(true);
      return user;
    } on NotFoundApiException {
      await _firebaseAuthDataSource.signOut();
      throw const GoogleAccountNotRegistered();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuthDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> logOut() async {
    try {
      await _authApiService.logout();
    } on ApiException {
      // Best-effort: the backend call only revokes refresh tokens as a
      // server-side courtesy. A failure here (e.g. backend unreachable)
      // must not block the user from signing out locally.
    }
    await _firebaseAuthDataSource.signOut();
    await _authLocalStorage.clear();
  }
}
