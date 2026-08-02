import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/widgets/stock_movement_timeline.dart';

void main() {
  testWidgets('always shows the "no movement history" placeholder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StockMovementTimeline())),
    );

    expect(find.text('No movement history yet'), findsOneWidget);
  });
}
