import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/business_step_screen.dart';

void main() {
  testWidgets('renders the core form elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BusinessStepScreen())),
    );

    expect(find.text('Business details'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Corporate ID'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets(
      'submitting empty required fields shows validation errors and does not call onNext',
      (
    tester,
  ) async {
    var nextCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: BusinessStepScreen(onNext: (_) => nextCalled = true)),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Country is required'), findsOneWidget);
    expect(find.text('Corporate ID is required'), findsOneWidget);
    expect(nextCalled, isFalse);
  });

  testWidgets('an invalid MCC code shows a validation error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BusinessStepScreen())),
    );

    await tester.enterText(find.widgetWithText(TextField, 'SE'), 'SE');
    await tester.enterText(
      find.widgetWithText(TextField, 'Business registration number'),
      '1234567812',
    );
    await tester.enterText(find.widgetWithText(TextField, '5941'), '12');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Enter a 4-digit Merchant Category Code'), findsOneWidget);
  });

  testWidgets('valid input calls onNext with trimmed, uppercased country',
      (tester) async {
    BusinessStepData? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: BusinessStepScreen(onNext: (data) => captured = data)),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'SE'), '  se  ');
    await tester.enterText(
      find.widgetWithText(TextField, 'Business registration number'),
      '1234567812',
    );
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.country, 'SE');
    expect(captured!.corporateId, '1234567812');
    expect(captured!.legalName, isNull);
    expect(captured!.mccCode, isNull);
  });
}
