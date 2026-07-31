import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/contact_step_screen.dart';

void main() {
  testWidgets('renders the core form elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ContactStepScreen())),
    );

    expect(find.text('Business contact'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets(
      'every field is optional — calls onNext with all null when left empty',
      (tester) async {
    ContactStepData? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: ContactStepScreen(onNext: (data) => captured = data)),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.email, isNull);
    expect(captured!.phoneCode, isNull);
    expect(captured!.phoneNumber, isNull);
  });

  testWidgets(
      'starting the phone number without a code shows a validation error',
      (tester) async {
    var nextCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home:
            Scaffold(body: ContactStepScreen(onNext: (_) => nextCalled = true)),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, '701234567'), '701234567');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Country calling code is required'), findsOneWidget);
    expect(nextCalled, isFalse);
  });

  testWidgets('onBack fires when Back is tapped', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home:
            Scaffold(body: ContactStepScreen(onBack: () => backTapped = true)),
      ),
    );

    await tester.tap(find.text('Back'));
    await tester.pump();

    expect(backTapped, isTrue);
  });
}
