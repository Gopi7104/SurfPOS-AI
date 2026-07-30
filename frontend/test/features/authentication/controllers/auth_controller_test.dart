import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  test('build() restores a persisted session', () async {
    final user = testAuthUser();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreSession: () async => user),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(authControllerProvider.future);

    expect(result, user);
  });

  test('build() resolves to null when there is no persisted session', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(authControllerProvider.future);

    expect(result, isNull);
  });

  test('logIn() transitions through loading to signed-in data', () async {
    final user = testAuthUser();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            logIn: ({required email, required password}) async => user,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);

    final future = container
        .read(authControllerProvider.notifier)
        .logIn(email: user.email, password: 'hunter2');

    expect(container.read(authControllerProvider).isLoading, isTrue);

    await future;

    expect(container.read(authControllerProvider).value, user);
  });

  test('logIn() surfaces a failure as AsyncError without crashing', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            logIn: ({required email, required password}) =>
                throw Exception('bad creds'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container
        .read(authControllerProvider.notifier)
        .logIn(email: 'x@x.com', password: 'wrong');

    expect(container.read(authControllerProvider).hasError, isTrue);
  });

  test('signUp() never forwards mobileNumber for anything observable',
      () async {
    final user = testAuthUser();
    String? capturedMobileNumber;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            signUp: ({
              required fullName,
              required email,
              required password,
              mobileNumber,
            }) async {
              capturedMobileNumber = mobileNumber;
              return user;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).signUp(
        fullName: 'Jane Doe', email: user.email, password: 'Str0ng!Pass');

    expect(capturedMobileNumber, isNull);
    expect(container.read(authControllerProvider).value, user);
  });

  test('logOut() clears the session back to null', () async {
    final user = testAuthUser();
    var loggedOut = false;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            restoreSession: () async => user,
            logOut: () async => loggedOut = true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).logOut();

    expect(loggedOut, isTrue);
    expect(container.read(authControllerProvider).value, isNull);
  });
}
