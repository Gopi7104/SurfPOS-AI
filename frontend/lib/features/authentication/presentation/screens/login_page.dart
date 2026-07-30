import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_scaffold_messenger.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/auth_user.dart';
import '../../domain/auth_failure.dart';
import '../../providers/auth_providers.dart';
import 'login_screen.dart';
import 'signup_page.dart';

/// Riverpod wrapper around the presentation-only [LoginScreen] — owns all
/// auth-state wiring, navigation, and error/success feedback so the screen
/// itself stays free of business logic (see docs/07_CODING_RULES.md § 8).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null || previous?.valueOrNull != null) return;

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Signed in successfully')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    });

    final authState = ref.watch(authControllerProvider);

    return LoginScreen(
      isLoading: authState.isLoading,
      errorMessage: authState.hasError
          ? AuthFailure.fromException(authState.error!).message
          : null,
      onSignIn: (email, password) => ref
          .read(authControllerProvider.notifier)
          .logIn(email: email, password: password),
      onGoogleSignIn: () =>
          ref.read(authControllerProvider.notifier).logInWithGoogle(),
      onForgotPassword: (email) => _handleForgotPassword(email),
      onCreateAccount: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignupPage()),
      ),
    );
  }

  Future<void> _handleForgotPassword(String email) async {
    final validationError = validateEmail(email);
    if (validationError != null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    await ref
        .read(passwordResetControllerProvider.notifier)
        .sendResetEmail(email);
    final state = ref.read(passwordResetControllerProvider);

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? AuthFailure.fromException(state.error!).message
              : 'Password reset email sent. Check your inbox.',
        ),
      ),
    );
  }
}
