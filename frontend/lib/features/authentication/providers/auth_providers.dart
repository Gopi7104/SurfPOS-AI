import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/password_reset_controller.dart';
import '../data/datasources/auth_api_service.dart';
import '../data/datasources/auth_local_storage.dart';
import '../data/datasources/firebase_auth_data_source.dart';
import '../data/models/auth_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';

/// DI wiring for the authentication feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3). Everything
/// downstream (controllers, widgets) depends on [authRepositoryProvider]'s
/// abstract type, not these concrete providers.

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return AuthLocalStorage(ref.watch(secureStorageServiceProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    authTokenProvider: () =>
        ref.read(firebaseAuthDataSourceProvider).getFreshIdToken(),
  );
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuthDataSource: ref.watch(firebaseAuthDataSourceProvider),
    authApiService: ref.watch(authApiServiceProvider),
    authLocalStorage: ref.watch(authLocalStorageProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

final passwordResetControllerProvider =
    AsyncNotifierProvider<PasswordResetController, void>(
  PasswordResetController.new,
);
