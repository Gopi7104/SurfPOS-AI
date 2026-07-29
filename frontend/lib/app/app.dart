import 'package:flutter/material.dart';

import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import 'themes/app_theme.dart';

/// Root app widget.
///
/// Routing is intentionally minimal right now: a plain [Navigator] push
/// chained off [SplashScreen.onReady], not `go_router`. `go_router` wiring
/// (per docs/02_ARCHITECTURE.md § 2 and .claude/decision.md ADR-007, still
/// **Proposed**, not yet confirmed) is deferred until that decision is
/// actually settled — introducing a router dependency isn't a decision to
/// make silently as a side effect of adding a second screen. Today the app
/// has two screens (Splash → Login — see docs/09_PROMPT_HISTORY.md);
/// Login itself does not yet navigate anywhere further (no Register/
/// Onboarding screens exist yet).
class SurfPosApp extends StatelessWidget {
  const SurfPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SurfPOS AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => SplashScreen(
          onReady: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ),
    );
  }
}
