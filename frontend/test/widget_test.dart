// Top-level app-shell smoke test — verifies main.dart/app.dart wiring
// (theme + initial route) actually boots. Per-screen tests live under
// test/features/, mirroring lib/features/ per docs/07_CODING_RULES.md § 3.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surfpos_ai/app/app.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/login_page.dart';
import 'package:surfpos_ai/features/authentication/presentation/screens/splash_screen.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';

import 'features/authentication/fakes/fake_auth_repository.dart';

void main() {
  testWidgets(
      'SurfPosApp renders the Splash screen on launch, then routes to Login', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // Splash's onReady awaits authControllerProvider's restored session
        // (see app.dart) — overridden here so the test never touches real
        // Firebase/network, and simply resolves to "no session".
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository())
        ],
        child: const SurfPosApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('SurfPOS AI'), findsOneWidget);
    expect(find.text('Powered by Surfboard Payments'), findsOneWidget);

    // SplashScreen's onReady fires after its hold duration and pushes past
    // the splash once the (fake) session check resolves.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
