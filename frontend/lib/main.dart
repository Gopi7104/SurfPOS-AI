import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/network/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolves the backend base URL every ApiClient uses — see
  // docs/23_ENVIRONMENT_CONFIGURATION.md. Must happen before runApp(): any
  // provider that constructs an ApiClient reads ApiConfig.baseUrl the first
  // time it's touched, which can happen as early as the first frame.
  await ApiConfig.initialize(environment: AppEnvironment.current);

  // Connectivity-audit instrumentation (see docs/23_ENVIRONMENT_CONFIGURATION.md and the
  // Connection Diagnostics screen under Settings) — prints the exact value every ApiClient
  // will use for this run, so "which backend is this build actually pointed at?" never has
  // to be guessed from reading source/config files.
  debugPrint(
      '[SurfPOS] AppEnvironment.current = ${AppEnvironment.current.name}');
  try {
    debugPrint('[SurfPOS] ApiConfig.baseUrl = ${ApiConfig.baseUrl}');
  } catch (error) {
    debugPrint('[SurfPOS] ApiConfig.baseUrl is NOT configured: $error');
  }

  try {
    await Firebase.initializeApp();
  } catch (error) {
    // No real Firebase project is configured yet for this app — there is no
    // google-services.json / GoogleService-Info.plist / firebase_options.dart
    // (see the Authentication module's Final Report, "Remaining Backend
    // Requirements"). Swallowing this keeps the UI reachable for
    // structural/visual verification; any real sign-in attempt still
    // surfaces a clear, honest Firebase error through the normal auth error
    // handling path (`AuthFailure.fromException`) once it's actually
    // attempted — this is not a mock or a bypass of Firebase.
    debugPrint(
        'Firebase.initializeApp() failed — no Firebase project configured yet: $error');
  }

  runApp(const ProviderScope(child: SurfPosApp()));
}
