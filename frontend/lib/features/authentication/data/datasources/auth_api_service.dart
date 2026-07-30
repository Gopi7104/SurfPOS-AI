import '../../../../core/network/api_client.dart';
import '../models/auth_user.dart';

/// Thin wrapper around [ApiClient] for the `/auth` routes — no business
/// logic, no Firebase calls, just request shaping and response parsing (see
/// `backend/src/routes/auth.routes.js`). Sequencing signup with a
/// subsequent client-side sign-in lives one layer up, in
/// `repositories/auth_repository_impl.dart`.
class AuthApiService {
  AuthApiService(this._client);

  final ApiClient _client;

  /// `POST /auth/signup` — creates the Firebase user server-side. Does not
  /// establish a client-side Firebase session; callers must sign in
  /// separately afterward.
  Future<AuthUser> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final data = await _client.post(
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// `POST /auth/login` — exchanges a Firebase ID token (from either
  /// email/password or Google sign-in) for the user's profile. Throws
  /// [NotFoundApiException] (`USER_PROFILE_NOT_FOUND`) if the token is valid
  /// but no profile exists yet — see the Google first-sign-in handling in
  /// `auth_repository_impl.dart`.
  Future<AuthUser> login(String idToken) async {
    final data = await _client.post('/auth/login', body: {'idToken': idToken});
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> me() async {
    final data = await _client.get('/auth/me', requiresAuth: true);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() {
    return _client.post('/auth/logout', requiresAuth: true);
  }
}
