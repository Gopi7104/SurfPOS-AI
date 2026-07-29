// Top-level app-shell smoke test — verifies main.dart/app.dart wiring
// (theme + initial route) actually boots. Per-screen tests live under
// test/features/, mirroring lib/features/ per docs/07_CODING_RULES.md § 3.
import 'package:flutter_test/flutter_test.dart';

import 'package:surfpos_ai/app/app.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SurfPosApp renders the Splash screen on launch', (tester) async {
    await tester.pumpWidget(const SurfPosApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('SurfPOS AI'), findsOneWidget);
    expect(find.text('Powered by Surfboard Payments'), findsOneWidget);

    // SplashScreen schedules a delayed navigation to Login once app.dart
    // wires a real onReady — settle past it so no timer is left pending
    // when the test ends (see splash_screen_test.dart for the same wait).
    await tester.pump(const Duration(milliseconds: 2300));
  });
}
