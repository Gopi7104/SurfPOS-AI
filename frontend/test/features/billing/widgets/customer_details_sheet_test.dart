import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/billing/models/customer_details.dart';
import 'package:surfpos_ai/features/billing/widgets/customer_details_sheet.dart';
import 'package:surfpos_ai/features/customers/models/customer_draft.dart';
import 'package:surfpos_ai/features/customers/models/customer_model.dart';
import 'package:surfpos_ai/features/customers/models/customer_purchase.dart';
import 'package:surfpos_ai/features/customers/providers/customer_providers.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_api_storage.dart';
import 'package:surfpos_ai/features/customers/repositories/customer_purchase_api_storage.dart';

class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

/// In-memory doubles for the Firebase-backed customer API storage classes —
/// see client_ai_tool_executor_test.dart's identical fakes for why
/// `customerRepositoryProvider` needs these overridden directly now instead
/// of flowing through [secureStorageServiceProvider].
class _FakeCustomerApiStorage implements CustomerApiStorage {
  List<CustomerModel> _items = [];

  @override
  Future<List<CustomerModel>> readAll() async => _items;

  @override
  Future<void> writeAll(List<CustomerModel> customers) async {
    _items = customers;
  }
}

class _FakeCustomerPurchaseApiStorage implements CustomerPurchaseApiStorage {
  List<CustomerPurchase> _items = [];

  @override
  Future<List<CustomerPurchase>> readAll() async => _items;

  @override
  Future<void> writeAll(List<CustomerPurchase> purchases) async {
    _items = purchases;
  }
}

List<Override> _customerStorageOverrides() => [
      customerApiStorageProvider.overrideWithValue(_FakeCustomerApiStorage()),
      customerPurchaseApiStorageProvider
          .overrideWithValue(_FakeCustomerPurchaseApiStorage()),
    ];

const _uid = 'uid-1';

Widget _wrap(ProviderContainer container) {
  CustomerDetails? result;
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showCustomerDetailsSheet(context, uid: _uid);
              },
              child: Text(result == null ? 'Open' : 'Done: ${result?.name}'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Skip closes the sheet with no customer details', (tester) async {
    final container = ProviderContainer(overrides: [
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService()),
      ..._customerStorageOverrides(),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
      'typing a phone that matches a real customer offers it, and selecting it autofills',
      (tester) async {
    final container = ProviderContainer(overrides: [
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService()),
      ..._customerStorageOverrides(),
    ]);
    addTearDown(container.dispose);
    await container.read(customerRepositoryProvider(_uid)).createCustomer(
        const CustomerDraft(
            firstName: 'Alex', lastName: 'Rivera', phone: '5551234567'));

    await tester.pumpWidget(_wrap(container));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Enter mobile number'), '5551234567');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Alex Rivera'), findsOneWidget);

    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(find.text('Linked to an existing customer record.'), findsOneWidget);
  });

  testWidgets('typing a phone with no match offers Create New Customer',
      (tester) async {
    final container = ProviderContainer(overrides: [
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService()),
      ..._customerStorageOverrides(),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Enter mobile number'), '5559876543');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No match — Create New Customer'), findsOneWidget);
  });
}
