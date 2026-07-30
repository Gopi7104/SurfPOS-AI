import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/widgets/buttons/app_primary_button.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/address_step_screen.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/business_step_screen.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/contact_step_screen.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/review_step_screen.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/store_step_screen.dart';

import 'test_surface.dart';

const _business = BusinessStepData(country: 'SE', corporateId: '1234567812', legalName: null, mccCode: null);
const _contact = ContactStepData();
const _address = AddressStepData(
  addressLine1: 'Main St 1',
  addressLine2: null,
  careOf: null,
  city: 'Stockholm',
  postalCode: '123 45',
);
const _store = StoreStepData(
  name: 'Main Street Store',
  email: 'store@example.com',
  phoneCode: '46',
  phoneNumber: '701234567',
  addressLine1: 'Main St 1',
  addressLine2: null,
  careOf: null,
  city: 'Stockholm',
  postalCode: '123 45',
);

Widget _buildScreen({VoidCallback? onSubmit, VoidCallback? onBack, bool isLoading = false, String? errorMessage}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ReviewStepScreen(
        business: _business,
        contact: _contact,
        address: _address,
        store: _store,
        onSubmit: onSubmit,
        onBack: onBack,
        isLoading: isLoading,
        errorMessage: errorMessage,
      ),
    ),
  );
}

void main() {
  testWidgets('renders a summary of every collected step', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_buildScreen());

    expect(find.text('Review & submit'), findsOneWidget);
    expect(find.textContaining('1234567812'), findsOneWidget);
    expect(find.textContaining('Main Street Store'), findsOneWidget);
    expect(find.text('Submit application'), findsOneWidget);
  });

  testWidgets('tapping Submit calls onSubmit', (tester) async {
    useTallTestSurface(tester);
    var submitted = false;
    await tester.pumpWidget(_buildScreen(onSubmit: () => submitted = true));

    await tester.tap(find.text('Submit application'));
    await tester.pump();

    expect(submitted, isTrue);
  });

  testWidgets('isLoading shows a spinner and disables Submit', (tester) async {
    useTallTestSurface(tester);
    var submitted = false;
    await tester.pumpWidget(_buildScreen(onSubmit: () => submitted = true, isLoading: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The button's label is replaced by the spinner while loading, so tap
    // the button itself rather than its (currently absent) text.
    await tester.tap(find.byType(AppPrimaryButton).first);
    await tester.pump();

    expect(submitted, isFalse);
  });

  testWidgets('errorMessage displays an error banner', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_buildScreen(errorMessage: 'You already have an application in progress.'));

    expect(find.text('You already have an application in progress.'), findsOneWidget);
  });
}
