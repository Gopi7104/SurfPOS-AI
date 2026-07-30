import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/merchant/data/models/merchant_application.dart';
import 'package:surfpos_ai/features/merchant/presentation/screens/result_step_screen.dart';

MerchantApplication _application({
  ApplicationStatus status = ApplicationStatus.applicationInitiated,
  String? applicationUrl = 'https://surfkyb.com/app-1',
  String? merchantId,
  String? storeId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return MerchantApplication(
    applicationId: 'app-1',
    merchantId: merchantId,
    storeId: storeId,
    applicationStatus: status,
    applicationUrl: applicationUrl,
    shortLinkUrl: null,
    submittedAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('shows the KYB link button while the application is initiated', (tester) async {
    String? openedUrl;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ResultStepScreen(application: _application(), onOpenKybLink: (url) => openedUrl = url),
        ),
      ),
    );

    expect(find.text('Application ID: app-1'), findsOneWidget);
    expect(find.text('Open KYB Application'), findsOneWidget);

    await tester.tap(find.text('Open KYB Application'));
    await tester.pump();

    expect(openedUrl, 'https://surfkyb.com/app-1');
  });

  testWidgets('hides the KYB link once the merchant is created and shows merchant/store ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ResultStepScreen(
            application: _application(
              status: ApplicationStatus.merchantCreated,
              merchantId: 'm-1',
              storeId: 's-1',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open KYB Application'), findsNothing);
    expect(find.text('Merchant ID: m-1'), findsOneWidget);
    expect(find.text('Store ID: s-1'), findsOneWidget);
  });

  testWidgets('tapping Refresh status calls onRefresh', (tester) async {
    var refreshed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ResultStepScreen(application: _application(), onRefresh: () => refreshed = true)),
      ),
    );

    await tester.tap(find.text('Refresh status'));
    await tester.pump();

    expect(refreshed, isTrue);
  });

  testWidgets('errorMessage displays an error banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ResultStepScreen(application: _application(), errorMessage: 'Could not refresh status.'),
        ),
      ),
    );

    expect(find.text('Could not refresh status.'), findsOneWidget);
  });
}
