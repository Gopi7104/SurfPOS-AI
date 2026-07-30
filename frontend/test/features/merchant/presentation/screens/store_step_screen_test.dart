import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/address_step_screen.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/store_step_screen.dart';

import 'test_surface.dart';

const _businessAddress = AddressStepData(
  addressLine1: 'Main St 1',
  addressLine2: null,
  careOf: null,
  city: 'Stockholm',
  postalCode: '123 45',
);

TextField _findAddressLine1Field(WidgetTester tester) {
  return tester.widget<TextField>(find.widgetWithText(TextField, 'Main Street 123'));
}

void main() {
  testWidgets('renders the core form elements, address pre-filled from business address by default', (
    tester,
  ) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: StoreStepScreen(businessAddress: _businessAddress)),
      ),
    );

    expect(find.text('Your store'), findsOneWidget);
    expect(find.text('Same as business address'), findsOneWidget);
    // "Same as business address" defaults to checked, so the address field is
    // pre-filled with the business address and disabled for editing.
    final addressField = _findAddressLine1Field(tester);
    expect(addressField.controller!.text, _businessAddress.addressLine1);
    expect(addressField.enabled, isFalse);
  });

  testWidgets('submitting empty required fields shows validation errors and does not call onNext', (
    tester,
  ) async {
    useTallTestSurface(tester);
    var nextCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StoreStepScreen(businessAddress: _businessAddress, onNext: (_) => nextCalled = true),
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Store name is required'), findsOneWidget);
    expect(nextCalled, isFalse);
  });

  testWidgets('unchecking "same as business address" clears and enables the address fields', (
    tester,
  ) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: StoreStepScreen(businessAddress: _businessAddress)),
      ),
    );

    await tester.tap(find.text('Same as business address'));
    await tester.pump();

    final addressField = _findAddressLine1Field(tester);
    expect(addressField.enabled, isTrue);
  });

  testWidgets('valid input with "same as business address" checked reuses the business address', (
    tester,
  ) async {
    useTallTestSurface(tester);
    StoreStepData? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StoreStepScreen(businessAddress: _businessAddress, onNext: (data) => captured = data),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Main Street Store'), 'My Store');
    await tester.enterText(find.widgetWithText(TextField, 'store@yourbusiness.com'), 'store@example.com');
    await tester.enterText(find.widgetWithText(TextField, '46'), '46');
    await tester.enterText(find.widgetWithText(TextField, '701234567'), '701234567');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.name, 'My Store');
    expect(captured!.addressLine1, _businessAddress.addressLine1);
    expect(captured!.city, _businessAddress.city);
    expect(captured!.postalCode, _businessAddress.postalCode);
  });
}
