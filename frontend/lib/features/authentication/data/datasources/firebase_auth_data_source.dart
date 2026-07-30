import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown when the user dismisses the Google account picker without
/// choosing an account. Deliberately not an [ApiException]/Firebase error —
/// callers should treat it as "nothing happened," not a failure to report.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Every direct Firebase Auth / Google Sign-In SDK call lives here — the
/// only place either package is imported outside this file (see
/// docs/07_CODING_RULES.md § 8). Returns plain Firebase ID token strings;
/// never persists them (see core/network/api_client.dart's doc comment for
/// why) and never talks to the SurfPOS backend directly (see
/// `repositories/auth_repository_impl.dart` for that orchestration).
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
      : _injectedFirebaseAuth = firebaseAuth;

  // Resolved lazily (not at construction) so that DI wiring (see
  // providers/auth_providers.dart) doesn't itself throw when no Firebase
  // project is configured yet (see main.dart) — `FirebaseAuth.instance`
  // calls `Firebase.app()` internally, which throws `[core/no-app]` the
  // instant it's touched. Deferring the lookup keeps that failure scoped to
  // an actual auth attempt (see class doc), not app startup.
  final FirebaseAuth? _injectedFirebaseAuth;
  FirebaseAuth get _firebaseAuth => _injectedFirebaseAuth ?? FirebaseAuth.instance;

  // GoogleSignIn.instance.initialize() must be called exactly once and
  // awaited before any other GoogleSignIn method — memoized so concurrent
  // callers await the same in-flight initialization rather than racing it.
  Future<void>? _googleSignInInitFuture;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitFuture ??= GoogleSignIn.instance.initialize();
  }

  // Firebase.apps.isEmpty guards against the unconfigured-project state (see
  // main.dart) — restoring a session with no Firebase app to check against
  // means there's nothing to restore, not an error.
  User? get currentUser =>
      Firebase.apps.isEmpty ? null : _firebaseAuth.currentUser;

  /// Signs in with an email/password pair that a `POST /auth/signup` call
  /// has already registered server-side (see
  /// `repositories/auth_repository_impl.dart#signUp` for that sequencing —
  /// this data source never creates a Firebase account itself). Returns a
  /// fresh Firebase ID token.
  Future<String> signInWithEmail(
      {required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await credential.user!.getIdToken();
    return idToken!;
  }

  /// Runs the interactive Google account picker, exchanges the resulting
  /// Google credential for a Firebase session, and returns a fresh Firebase
  /// ID token. Throws [GoogleSignInCancelled] if the user dismisses the
  /// picker, or a [FirebaseAuthException] (e.g.
  /// `account-exists-with-different-credential`) for any other failure —
  /// see `domain/auth_failure.dart` for how each is mapped to user-facing
  /// copy.
  Future<String> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      rethrow;
    }

    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message: 'Google did not return an identity token for this sign-in.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseIdToken = await userCredential.user!.getIdToken();
    return firebaseIdToken!;
  }

  /// Re-reads the current Firebase user's ID token, refreshing it first if
  /// [forceRefresh] is true or the cached one is close to expiring — Firebase
  /// handles the actual refresh logic internally.
  Future<String?> getFreshIdToken({bool forceRefresh = false}) {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh) ??
        Future.value();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignInInitFuture != null) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
