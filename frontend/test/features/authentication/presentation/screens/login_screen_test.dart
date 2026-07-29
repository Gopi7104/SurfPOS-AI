import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/widgets/buttons/app_primary_button.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/login_screen.dart';

// Every test wraps LoginScreen with `theme: AppTheme.light` rather than a
// bare MaterialApp — the app always renders under this theme in practice
// (it sets `splashFactory: InkRipple.splashFactory` specifically to avoid
// the Material 3 default `InkSparkle` ripple, which needs a shader asset
// that isn't reliably available on this dev machine — see
// .claude/projectStatus.md § Known Issues #5). Testing under the real
// theme is also simply more representative of the actual app.

void main() {
  testWidgets('LoginScreen renders the core form elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });

  testWidgets(
    'Submitting empty fields shows validation errors and does not call onSignIn',
    (tester) async {
      var signInCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(onSignIn: (_, __) => signInCalled = true),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter your email or phone number'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(signInCalled, isFalse);
    },
  );

  testWidgets('Submitting valid fields calls onSignIn with trimmed values', (
    tester,
  ) async {
    String? capturedIdentifier;
    String? capturedPassword;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          onSignIn: (identifier, password) {
            capturedIdentifier = identifier;
            capturedPassword = password;
          },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'you@business.com'),
      '  owner@surfpos.se  ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter your password'),
      'hunter2',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(capturedIdentifier, 'owner@surfpos.se');
    expect(capturedPassword, 'hunter2');
  });

  testWidgets('Forgot password and create account callbacks fire', (
    tester,
  ) async {
    var forgotTapped = false;
    var createTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          onForgotPassword: () => forgotTapped = true,
          onCreateAccount: () => createTapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.tap(find.text('Create one'));
    await tester.pump();

    expect(forgotTapped, isTrue);
    expect(createTapped, isTrue);
  });

  testWidgets('isLoading shows a spinner and disables interaction', (
    tester,
  ) async {
    var signInCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          isLoading: true,
          onSignIn: (_, __) => signInCalled = true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The button's label is replaced by the spinner while loading, so tap
    // the button itself rather than its (currently absent) text.
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pump();

    expect(signInCalled, isFalse);
  });

  testWidgets('errorMessage displays an error banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(errorMessage: 'Invalid email or password'),
      ),
    );

    expect(find.text('Invalid email or password'), findsOneWidget);
  });
}
