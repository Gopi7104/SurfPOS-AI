import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/demo_data_controller.dart';
import '../models/demo_business_snapshot.dart';
import '../repositories/demo_data_local_storage.dart';

/// DI wiring for the demo-data feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3), reusing the
/// authentication feature's shared [secureStorageServiceProvider] exactly
/// like `productImageLocalStorageProvider`/`settingsLocalStorageProvider`
/// do, rather than redeclaring a second `SecureStorageService`.
final demoDataLocalStorageProvider =
    Provider.autoDispose.family<DemoDataLocalStorage, String>((ref, uid) {
  return DemoDataLocalStorage(ref.watch(secureStorageServiceProvider), uid);
});

/// Keyed by Firebase uid — never a global singleton, so a different
/// signed-in account can never see a previous account's generated demo
/// data, even transiently.
final demoDataControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DemoDataController, DemoBusinessSnapshot?, String>(
  DemoDataController.new,
);
