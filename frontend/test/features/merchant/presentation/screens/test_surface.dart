import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Several onboarding-step forms are taller than flutter_test's default
/// 800x600 surface, which leaves lower elements (e.g. the "Next" button)
/// scrolled out of view and unreachable by `tester.tap`. Mirrors
/// `login_screen_test.dart`'s `_useTallTestSurface`.
void useTallTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
