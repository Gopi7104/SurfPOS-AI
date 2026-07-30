import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth_user.dart';
import '../providers/auth_providers.dart';

/// Session state for the whole app: `null` data = signed out, non-null =
/// signed in. `build()` restores a persisted session on first read (see
/// `AuthRepository.restoreSession`), so the Splash/root routing widget can
/// simply watch this provider instead of re-implementing session checks.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    String? mobileNumber,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
            fullName: fullName,
            email: email,
            password: password,
            mobileNumber: mobileNumber,
          ),
    );
  }

  Future<void> logIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .logIn(email: email, password: password),
    );
  }

  Future<void> logInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).logInWithGoogle());
  }

  Future<void> logOut() async {
    await ref.read(authRepositoryProvider).logOut();
    state = const AsyncValue.data(null);
  }
}
