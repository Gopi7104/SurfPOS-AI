import 'package:flutter/material.dart';

/// Root-level [ScaffoldMessengerState] key so success/error SnackBars
/// (e.g. "Signed in successfully") survive a `pushAndRemoveUntil` — the
/// per-screen `Scaffold`'s own messenger is torn down along with the route
/// it belongs to, but this one lives as long as [SurfPosApp.MaterialApp]
/// does.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
