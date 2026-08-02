import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/ai/widgets/chat_suggestions.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_business_snapshot.dart';

const _uid = 'uid-1';

class _FakeSecureStorageService implements SecureStorageService {
  _FakeSecureStorageService([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

Widget _wrap(ValueChanged<String> onSelect,
    {Map<String, String>? storageSeed}) {
  return ProviderScope(
    overrides: [
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService(storageSeed)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChatSuggestions(uid: _uid, onSelect: onSelect),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'shows every always-on suggestion and Generate Demo Data when no demo data exists',
      (tester) async {
    await tester.pumpWidget(_wrap((_) {}));
    await tester.pump();

    for (final label in const [
      "Today's Sales",
      'Low Stock',
      'Best Seller',
      'Search Product',
      'Inventory Value',
      'Top Customer',
      'Business Insights',
      'Open Billing',
      'Open Inventory',
      'Open Reports',
      'Open Customers',
      'Generate Demo Data',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('hides Generate Demo Data once demo data already exists',
      (tester) async {
    final snapshot = DemoBusinessSnapshot(
      merchantName: 'Test',
      storeName: 'Store',
      generatedAt: DateTime.now(),
      categories: const [],
      products: const [],
      customers: const [],
      sales: const [],
      receipts: const [],
    );
    await tester.pumpWidget(_wrap(
      (_) {},
      storageSeed: {'demo_data.snapshot.$_uid': jsonEncode(snapshot.toJson())},
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Generate Demo Data'), findsNothing);
    expect(find.text("Today's Sales"), findsOneWidget);
  });

  testWidgets('tapping a suggestion calls onSelect with its exact label',
      (tester) async {
    String? selected;
    await tester.pumpWidget(_wrap((value) => selected = value));
    await tester.pump();

    await tester.tap(find.text('Low Stock'));
    await tester.pump();

    expect(selected, 'Low Stock');
  });
}
