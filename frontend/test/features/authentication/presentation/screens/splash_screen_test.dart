import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen fades and scales its content in without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );

    // Mid-animation frame.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Animation complete.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('SurfPOS AI'), findsOneWidget);
  });

  testWidgets('SplashScreen invokes onReady after its hold duration', (
    tester,
  ) async {
    var readyCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(onReady: () => readyCalled = true),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(readyCalled, isFalse);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(readyCalled, isTrue);
  });
}
