import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/widgets/buttons/app_primary_button.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/signup_screen.dart';

// See login_screen_test.dart's file-level comment for why every test wraps
// SignupScreen with `theme: AppTheme.light` rather than a bare MaterialApp.

/// SignupScreen has more fields than LoginScreen and is taller than
/// flutter_test's default 800x600 surface — see login_screen_test.dart's
/// `_useTallTestSurface` for why this is needed before tapping anything
/// near the bottom of the form.
void _useTallTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('SignupScreen renders the core form elements', (tester) async {
    _useTallTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SignupScreen()),
    );

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mobile Number (optional)'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'Submitting empty required fields shows validation errors and does not call onSignUp',
    (tester) async {
      _useTallTestSurface(tester);
      var signUpCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home:
              SignupScreen(onSignUp: (_, __, ___, ____) => signUpCalled = true),
        ),
      );

      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsAtLeastNWidgets(1));
      expect(find.text('Confirm your password'), findsOneWidget);
      expect(signUpCalled, isFalse);
    },
  );

  testWidgets('Mismatched passwords are rejected without calling onSignUp',
      (tester) async {
    _useTallTestSurface(tester);
    var signUpCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(onSignUp: (_, __, ___, ____) => signUpCalled = true),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Jane Doe'), 'Jane Doe');
    await tester.enterText(
      find.widgetWithText(TextField, 'you@business.com'),
      'jane@surfpos.se',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Create a password'),
      'Str0ng!Pass',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Re-enter your password'),
      'Different1!',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(signUpCalled, isFalse);
  });

  testWidgets(
    'Submitting valid fields calls onSignUp with trimmed values, mobile null when blank',
    (tester) async {
      _useTallTestSurface(tester);
      String? capturedFullName;
      String? capturedEmail;
      String? capturedMobileNumber;
      String? capturedPassword;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SignupScreen(
            onSignUp: (fullName, email, mobileNumber, password) {
              capturedFullName = fullName;
              capturedEmail = email;
              capturedMobileNumber = mobileNumber;
              capturedPassword = password;
            },
          ),
        ),
      );

      await tester.enterText(
          find.widgetWithText(TextField, 'Jane Doe'), '  Jane Doe  ');
      await tester.enterText(
        find.widgetWithText(TextField, 'you@business.com'),
        '  jane@surfpos.se  ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Create a password'),
        'Str0ng!Pass',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Re-enter your password'),
        'Str0ng!Pass',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(capturedFullName, 'Jane Doe');
      expect(capturedEmail, 'jane@surfpos.se');
      expect(capturedMobileNumber, isNull);
      expect(capturedPassword, 'Str0ng!Pass');
    },
  );

  testWidgets(
      'A typed mobile number is passed through untrimmed of surrounding spaces',
      (
    tester,
  ) async {
    _useTallTestSurface(tester);
    String? capturedMobileNumber;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(
          onSignUp: (_, __, mobileNumber, ____) =>
              capturedMobileNumber = mobileNumber,
        ),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Jane Doe'), 'Jane Doe');
    await tester.enterText(
      find.widgetWithText(TextField, 'you@business.com'),
      'jane@surfpos.se',
    );
    await tester.enterText(
        find.widgetWithText(TextField, '070 123 45 67'), '0701234567');
    await tester.enterText(
      find.widgetWithText(TextField, 'Create a password'),
      'Str0ng!Pass',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Re-enter your password'),
      'Str0ng!Pass',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(capturedMobileNumber, '0701234567');
  });

  testWidgets('Google sign-in and Login callbacks fire', (tester) async {
    _useTallTestSurface(tester);
    var googleTapped = false;
    var loginTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(
          onGoogleSignIn: () => googleTapped = true,
          onLogin: () => loginTapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(googleTapped, isTrue);
    expect(loginTapped, isTrue);
  });

  testWidgets('isLoading shows a spinner and disables interaction',
      (tester) async {
    _useTallTestSurface(tester);
    var signUpCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(
          isLoading: true,
          onSignUp: (_, __, ___, ____) => signUpCalled = true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pump();

    expect(signUpCalled, isFalse);
  });

  testWidgets('errorMessage displays an error banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SignupScreen(
            errorMessage: 'An account with this email already exists'),
      ),
    );

    expect(
        find.text('An account with this email already exists'), findsOneWidget);
  });
}
