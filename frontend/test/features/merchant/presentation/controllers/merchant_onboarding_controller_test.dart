import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/merchant/data/models/merchant_application.dart';
import 'package:surfpos_ai/features/merchant/presentation/providers/merchant_onboarding_providers.dart';

import '../../fakes/fake_merchant_onboarding_repository.dart';

const _uidA = 'uid-merchant-a';
const _uidB = 'uid-merchant-b';

Map<String, dynamic> _validSubmitArgs() => {
      'country': 'SE',
      'corporateId': '1234567812',
      'organisationAddressLine1': 'Main St 1',
      'organisationCity': 'Stockholm',
      'organisationCountryCode': 'SE',
      'organisationPostalCode': '123 45',
      'storeName': 'Main Street Store',
      'storeEmail': 'store@example.com',
      'storePhoneCode': '46',
      'storePhoneNumber': '701234567',
      'storeAddressLine1': 'Main St 1',
      'storeCity': 'Stockholm',
      'storeCountryCode': 'SE',
      'storePostalCode': '123 45',
    };

void main() {
  test('build() restores a cached application', () async {
    final application = testMerchantApplication();
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
              restoreCachedApplication: () async => application),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(merchantOnboardingControllerProvider(_uidA).future);

    expect(result, application);
  });

  test('build() resolves to null when nothing is cached', () async {
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider
            .overrideWith((ref, uid) => FakeMerchantOnboardingRepository()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(merchantOnboardingControllerProvider(_uidA).future);

    expect(result, isNull);
  });

  test('submit() transitions through loading to a submitted application',
      () async {
    final application = testMerchantApplication();
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
            submit: ({
              required country,
              required corporateId,
              legalName,
              mccCode,
              required organisationAddressLine1,
              organisationAddressLine2,
              organisationCareOf,
              required organisationCity,
              required organisationCountryCode,
              required organisationPostalCode,
              organisationPhoneCode,
              organisationPhoneNumber,
              organisationEmail,
              required storeName,
              required storeEmail,
              required storePhoneCode,
              required storePhoneNumber,
              required storeAddressLine1,
              storeAddressLine2,
              storeCareOf,
              required storeCity,
              required storeCountryCode,
              required storePostalCode,
            }) async =>
                application,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(merchantOnboardingControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(merchantOnboardingControllerProvider(_uidA).future);

    final args = _validSubmitArgs();
    final future = container
        .read(merchantOnboardingControllerProvider(_uidA).notifier)
        .submit(
          country: args['country'],
          corporateId: args['corporateId'],
          organisationAddressLine1: args['organisationAddressLine1'],
          organisationCity: args['organisationCity'],
          organisationCountryCode: args['organisationCountryCode'],
          organisationPostalCode: args['organisationPostalCode'],
          storeName: args['storeName'],
          storeEmail: args['storeEmail'],
          storePhoneCode: args['storePhoneCode'],
          storePhoneNumber: args['storePhoneNumber'],
          storeAddressLine1: args['storeAddressLine1'],
          storeCity: args['storeCity'],
          storeCountryCode: args['storeCountryCode'],
          storePostalCode: args['storePostalCode'],
        );

    expect(
        container.read(merchantOnboardingControllerProvider(_uidA)).isLoading,
        isTrue);

    await future;

    expect(container.read(merchantOnboardingControllerProvider(_uidA)).value,
        application);
  });

  test('submit() surfaces a failure as AsyncError without crashing', () async {
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
            submit: ({
              required country,
              required corporateId,
              legalName,
              mccCode,
              required organisationAddressLine1,
              organisationAddressLine2,
              organisationCareOf,
              required organisationCity,
              required organisationCountryCode,
              required organisationPostalCode,
              organisationPhoneCode,
              organisationPhoneNumber,
              organisationEmail,
              required storeName,
              required storeEmail,
              required storePhoneCode,
              required storePhoneNumber,
              required storeAddressLine1,
              storeAddressLine2,
              storeCareOf,
              required storeCity,
              required storeCountryCode,
              required storePostalCode,
            }) =>
                throw Exception('duplicate application'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(merchantOnboardingControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(merchantOnboardingControllerProvider(_uidA).future);
    final args = _validSubmitArgs();
    await container
        .read(merchantOnboardingControllerProvider(_uidA).notifier)
        .submit(
          country: args['country'],
          corporateId: args['corporateId'],
          organisationAddressLine1: args['organisationAddressLine1'],
          organisationCity: args['organisationCity'],
          organisationCountryCode: args['organisationCountryCode'],
          organisationPostalCode: args['organisationPostalCode'],
          storeName: args['storeName'],
          storeEmail: args['storeEmail'],
          storePhoneCode: args['storePhoneCode'],
          storePhoneNumber: args['storePhoneNumber'],
          storeAddressLine1: args['storeAddressLine1'],
          storeCity: args['storeCity'],
          storeCountryCode: args['storeCountryCode'],
          storePostalCode: args['storePostalCode'],
        );

    expect(container.read(merchantOnboardingControllerProvider(_uidA)).hasError,
        isTrue);
  });

  test(
      'submit() is a no-op while a submission is already in flight (duplicate-submission guard)',
      () async {
    var submitCallCount = 0;
    final application = testMerchantApplication();
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
            submit: ({
              required country,
              required corporateId,
              legalName,
              mccCode,
              required organisationAddressLine1,
              organisationAddressLine2,
              organisationCareOf,
              required organisationCity,
              required organisationCountryCode,
              required organisationPostalCode,
              organisationPhoneCode,
              organisationPhoneNumber,
              organisationEmail,
              required storeName,
              required storeEmail,
              required storePhoneCode,
              required storePhoneNumber,
              required storeAddressLine1,
              storeAddressLine2,
              storeCareOf,
              required storeCity,
              required storeCountryCode,
              required storePostalCode,
            }) async {
              submitCallCount++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return application;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // autoDispose providers are torn down once nothing is actively listening — a plain
    // container.read() between the two overlapping submit() calls below doesn't count as a
    // listener, so without this the provider can be disposed and recreated mid-test.
    final sub = container.listen(
        merchantOnboardingControllerProvider(_uidA), (_, __) {});
    addTearDown(sub.close);

    await container.read(merchantOnboardingControllerProvider(_uidA).future);
    final args = _validSubmitArgs();
    final notifier =
        container.read(merchantOnboardingControllerProvider(_uidA).notifier);

    final first = notifier.submit(
      country: args['country'],
      corporateId: args['corporateId'],
      organisationAddressLine1: args['organisationAddressLine1'],
      organisationCity: args['organisationCity'],
      organisationCountryCode: args['organisationCountryCode'],
      organisationPostalCode: args['organisationPostalCode'],
      storeName: args['storeName'],
      storeEmail: args['storeEmail'],
      storePhoneCode: args['storePhoneCode'],
      storePhoneNumber: args['storePhoneNumber'],
      storeAddressLine1: args['storeAddressLine1'],
      storeCity: args['storeCity'],
      storeCountryCode: args['storeCountryCode'],
      storePostalCode: args['storePostalCode'],
    );
    // A second call while the first is still in flight must be ignored.
    final second = notifier.submit(
      country: args['country'],
      corporateId: args['corporateId'],
      organisationAddressLine1: args['organisationAddressLine1'],
      organisationCity: args['organisationCity'],
      organisationCountryCode: args['organisationCountryCode'],
      organisationPostalCode: args['organisationPostalCode'],
      storeName: args['storeName'],
      storeEmail: args['storeEmail'],
      storePhoneCode: args['storePhoneCode'],
      storePhoneNumber: args['storePhoneNumber'],
      storeAddressLine1: args['storeAddressLine1'],
      storeCity: args['storeCity'],
      storeCountryCode: args['storeCountryCode'],
      storePostalCode: args['storePostalCode'],
    );

    await Future.wait([first, second]);

    expect(submitCallCount, 1);
  });

  test(
      'refreshStatus() polls with the current application id and updates state',
      () async {
    final initial = testMerchantApplication(applicationId: 'app-1');
    final refreshed = testMerchantApplication(
      applicationId: 'app-1',
      applicationStatus: ApplicationStatus.merchantCreated,
      merchantId: 'm-1',
      storeId: 's-1',
    );
    String? capturedApplicationId;
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
            restoreCachedApplication: () async => initial,
            refreshStatus: (applicationId) async {
              capturedApplicationId = applicationId;
              return refreshed;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(merchantOnboardingControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(merchantOnboardingControllerProvider(_uidA).future);
    await container
        .read(merchantOnboardingControllerProvider(_uidA).notifier)
        .refreshStatus();

    expect(capturedApplicationId, 'app-1');
    expect(container.read(merchantOnboardingControllerProvider(_uidA)).value,
        refreshed);
  });

  test('refreshStatus() is a no-op when there is nothing to refresh yet',
      () async {
    var called = false;
    final container = ProviderContainer(
      overrides: [
        merchantOnboardingRepositoryProvider.overrideWith(
          (ref, uid) => FakeMerchantOnboardingRepository(
            refreshStatus: (applicationId) async {
              called = true;
              return testMerchantApplication();
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(merchantOnboardingControllerProvider(_uidA).future);
    await container
        .read(merchantOnboardingControllerProvider(_uidA).notifier)
        .refreshStatus();

    expect(called, isFalse);
  });

  group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test('two different uids never share cached application state', () async {
      final applicationA =
          testMerchantApplication(applicationId: 'app-a', merchantId: 'm-a');
      final container = ProviderContainer(
        overrides: [
          merchantOnboardingRepositoryProvider.overrideWith(
            (ref, uid) => FakeMerchantOnboardingRepository(
                restoreCachedApplication: () async => applicationA),
          ),
        ],
      );
      addTearDown(container.dispose);

      final resultA = await container
          .read(merchantOnboardingControllerProvider(_uidA).future);

      final containerBOverride = ProviderContainer(
        overrides: [
          merchantOnboardingRepositoryProvider.overrideWith(
            (ref, uid) => FakeMerchantOnboardingRepository(
                restoreCachedApplication: () async => null),
          ),
        ],
      );
      addTearDown(containerBOverride.dispose);
      final resultB = await containerBOverride
          .read(merchantOnboardingControllerProvider(_uidB).future);

      expect(resultA?.applicationId, 'app-a');
      expect(resultB, isNull);
    });
  });
}
