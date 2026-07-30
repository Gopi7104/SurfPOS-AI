import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
