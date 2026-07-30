import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/address_step_screen.dart';

import 'test_surface.dart';

void main() {
  testWidgets('renders the core form elements', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const Scaffold(body: AddressStepScreen())),
    );

    expect(find.text('Business address'), findsOneWidget);
    expect(find.text('Address line 1'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Postal code'), findsOneWidget);
  });

  testWidgets('submitting empty required fields shows validation errors and does not call onNext', (
    tester,
  ) async {
    useTallTestSurface(tester);
    var nextCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AddressStepScreen(onNext: (_) => nextCalled = true)),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Address is required'), findsOneWidget);
    expect(find.text('City is required'), findsOneWidget);
    expect(find.text('Postal code is required'), findsOneWidget);
    expect(nextCalled, isFalse);
  });

  testWidgets('valid input calls onNext with trimmed values, optional fields null when blank', (
    tester,
  ) async {
    useTallTestSurface(tester);
    AddressStepData? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AddressStepScreen(onNext: (data) => captured = data)),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Main Street 123'), '  Main St 1  ');
    await tester.enterText(find.widgetWithText(TextField, 'Stockholm'), 'Stockholm');
    await tester.enterText(find.widgetWithText(TextField, '123 45'), '123 45');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.addressLine1, 'Main St 1');
    expect(captured!.city, 'Stockholm');
    expect(captured!.postalCode, '123 45');
    expect(captured!.addressLine2, isNull);
    expect(captured!.careOf, isNull);
  });
}
