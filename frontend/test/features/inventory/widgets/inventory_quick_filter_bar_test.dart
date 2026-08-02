import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_query.dart';
import 'package:surfpos_ai/features/inventory/widgets/inventory_quick_filter_bar.dart';

Widget _wrap({
  required InventoryQuery query,
  required ValueChanged<InventoryQuery> onQueryChanged,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body:
          InventoryQuickFilterBar(query: query, onQueryChanged: onQueryChanged),
    ),
  );
}

void main() {
  testWidgets('tapping Low Stock applies the stock filter and clears sort',
      (tester) async {
    InventoryQuery? changed;
    await tester.pumpWidget(_wrap(
      query: const InventoryQuery(sortOption: InventorySortOption.newest),
      onQueryChanged: (q) => changed = q,
    ));

    await tester.tap(find.text('Low Stock'));
    await tester.pump();

    expect(changed?.stockFilter, StockFilter.lowStock);
    expect(changed?.sortOption, isNull);
  });

  testWidgets(
      'tapping Recently Added sets the newest sort option and clears stock filter',
      (tester) async {
    InventoryQuery? changed;
    await tester.pumpWidget(_wrap(
      query: const InventoryQuery(stockFilter: StockFilter.outOfStock),
      onQueryChanged: (q) => changed = q,
    ));

    await tester.tap(find.text('Recently Added'));
    await tester.pump();

    expect(changed?.sortOption, InventorySortOption.newest);
    expect(changed?.stockFilter, StockFilter.all);
  });

  testWidgets('Most Sold, Imported via Barcode, and Manual Entry are disabled',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      query: const InventoryQuery(),
      onQueryChanged: (_) => tapped = true,
    ));

    for (final label in ['Most Sold', 'Imported via Barcode', 'Manual Entry']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label), warnIfMissed: false);
      await tester.pump();
    }

    expect(tapped, isFalse);
  });
}
