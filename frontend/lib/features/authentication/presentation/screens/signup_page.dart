import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_scaffold_messenger.dart';
import '../../../../app/main_shell_page.dart';
import '../../data/models/auth_user.dart';
import '../../domain/auth_failure.dart';
import '../../providers/auth_providers.dart';
import 'signup_screen.dart';

/// Riverpod wrapper around the presentation-only [SignupScreen] — mirrors
/// [LoginPage]'s wiring pattern (see its doc comment).
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null || previous?.valueOrNull != null) return;

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellPage()),
        (route) => false,
      );
    });

    final authState = ref.watch(authControllerProvider);

    return SignupScreen(
      isLoading: authState.isLoading,
      errorMessage: authState.hasError
          ? AuthFailure.fromException(authState.error!).message
          : null,
      onSignUp: (fullName, email, mobileNumber, password) =>
          ref.read(authControllerProvider.notifier).signUp(
                fullName: fullName,
                email: email,
                password: password,
                mobileNumber: mobileNumber,
              ),
      onGoogleSignIn: () =>
          ref.read(authControllerProvider.notifier).logInWithGoogle(),
      onLogin: () => Navigator.of(context).pop(),
    );
  }
}
