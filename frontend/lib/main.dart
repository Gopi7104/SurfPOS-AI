import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';

// Firebase config comes from the platform-native files (android/app/google-services.json,
// ios/Runner/GoogleService-Info.plist) — no generated firebase_options.dart / no FirebaseOptions
// passed here, so nothing app-specific is hardcoded in source. See docs/14_DEVELOPER_GUIDE.md § 5.
// The app only ever uses Firebase Authentication directly — Realtime Database/Storage are backend
// -only (docs/02_ARCHITECTURE.md § 2), so Firebase.initializeApp() failing here should surface
// loudly rather than be swallowed, since Auth is the one Firebase capability this app owns.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SurfPosApp());
}
