import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/demo_business_snapshot.dart';
import '../providers/demo_data_providers.dart';
import '../services/demo_data_generator.dart';

/// The generated demo dataset (or `null` if none has been generated yet)
/// for exactly one Firebase uid — see [demoDataControllerProvider], a
/// `.family` provider, same cross-user isolation rule every controller in
/// this app follows.
///
/// This is a **presentation-only** feature: [generate] never writes to
/// `InventoryRepository`/`CustomerRepository`/any real repository — it only
/// builds a [DemoBusinessSnapshot] in memory ([DemoDataGenerator]) and
/// persists it to its own local blob ([DemoDataLocalStorage]). It is the
/// one and only thing the redesigned Dashboard reads to show a populated,
/// "premium POS" look before any real sales history exists — see
/// `ReportsRepositoryImpl`'s header comment for why that history doesn't
/// exist yet. [clear] only ever deletes this module's own blob; it can
/// never touch, and never overwrites, any real merchant data.
class DemoDataController
    extends AutoDisposeFamilyAsyncNotifier<DemoBusinessSnapshot?, String> {
  @override
  Future<DemoBusinessSnapshot?> build(String uid) {
    return ref.read(demoDataLocalStorageProvider(uid)).read();
  }

  Future<void> generate({String? merchantName, String? storeName}) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final snapshot = const DemoDataGenerator()
          .generate(merchantName: merchantName, storeName: storeName);
      await ref.read(demoDataLocalStorageProvider(arg)).write(snapshot);
      return snapshot;
    });
  }

  Future<void> clear() async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(demoDataLocalStorageProvider(arg)).clear();
      return null;
    });
  }
}
