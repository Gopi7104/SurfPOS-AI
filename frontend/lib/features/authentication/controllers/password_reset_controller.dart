import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Standalone `AsyncNotifier<void>` for the "Forgot password?" flow — kept
/// separate from [AuthController] since sending a reset email neither reads
/// nor changes the signed-in session state.
class PasswordResetController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }
}
