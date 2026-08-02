import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_status.dart';
import '../providers/ai_providers.dart';

/// Backs Settings' Developer "AI" section — provider/current-model info
/// only, no live OpenRouter call (see [AiConnectionTestController] for the
/// one that actually calls OpenRouter).
class AiStatusController extends AutoDisposeAsyncNotifier<AiProviderStatus> {
  @override
  Future<AiProviderStatus> build() =>
      ref.read(aiRepositoryProvider).getStatus();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(aiRepositoryProvider).getStatus());
  }
}

/// "Test Connection" on Settings' Developer section — a one-shot action,
/// not loaded on `build()`, since it makes a real OpenRouter round trip and
/// must only run when the merchant explicitly asks for it.
class AiConnectionTestController
    extends AutoDisposeAsyncNotifier<AiConnectionTestResult?> {
  @override
  AiConnectionTestResult? build() => null;

  Future<void> run() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(aiRepositoryProvider).testConnection());
  }
}
