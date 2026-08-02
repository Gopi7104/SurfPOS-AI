import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/ai_chat_controller.dart';
import '../controllers/ai_chat_state.dart';
import '../controllers/ai_status_controller.dart';
import '../datasources/ai_remote_datasource.dart';
import '../datasources/ai_remote_datasource_impl.dart';
import '../models/ai_status.dart';
import '../repositories/ai_repository.dart';
import '../repositories/ai_repository_impl.dart';

/// DI wiring for the AI feature — the only place these concrete classes are
/// constructed (see docs/07_CODING_RULES.md § 3). Reuses the authentication
/// feature's shared [apiClientProvider] exactly like every other feature
/// (dashboard, inventory, billing, settings).

final aiRemoteDatasourceProvider = Provider<AiRemoteDatasource>((ref) {
  return AiRemoteDatasourceImpl(apiClient: ref.watch(apiClientProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(datasource: ref.watch(aiRemoteDatasourceProvider));
});

final aiChatControllerProvider =
    NotifierProvider.autoDispose.family<AiChatController, AiChatState, String>(
  AiChatController.new,
);

final aiStatusControllerProvider =
    AsyncNotifierProvider.autoDispose<AiStatusController, AiProviderStatus>(
  AiStatusController.new,
);

final aiConnectionTestControllerProvider = AsyncNotifierProvider.autoDispose<
    AiConnectionTestController, AiConnectionTestResult?>(
  AiConnectionTestController.new,
);
