import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/authentication/presentation/screens/login_page.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../features/authentication/providers/auth_providers.dart';
import 'app_scaffold_messenger.dart';
import 'main_shell_page.dart';
import 'themes/app_theme.dart';

/// Root app widget.
///
/// Routing is intentionally minimal right now: a plain [Navigator] push
/// chained off [SplashScreen.onReady], not `go_router`. `go_router` wiring
/// (per docs/02_ARCHITECTURE.md § 2 and .claude/decision.md ADR-007, still
/// **Proposed**, not yet confirmed) is deferred until that decision is
/// actually settled — introducing a router dependency isn't a decision to
/// make silently as a side effect of adding a second screen.
///
/// Splash now waits on [authControllerProvider]'s restored session (see
/// `AuthRepository.restoreSession`) before deciding whether to land on
/// [LoginPage] or [MainShellPage] — this is a genuine session check, not
/// just the splash animation timer. Login/Signup → shell (and shell's
/// Settings tab → Login on logout) both use `pushAndRemoveUntil` so the
/// previous screen is fully removed from the stack — signed-in users can't
/// navigate back to Login, and signed-out users can't navigate back to the
/// shell.
class SurfPosApp extends ConsumerWidget {
  const SurfPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SurfPOS AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: Builder(
        builder: (context) => SplashScreen(
          onReady: () => _routeFromSplash(context, ref),
        ),
      ),
    );
  }

  Future<void> _routeFromSplash(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(authControllerProvider.future);
    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            user == null ? const LoginPage() : const MainShellPage(),
      ),
    );
  }
}
