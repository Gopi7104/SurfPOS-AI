import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/inventory/models/product_image_exception.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';
import 'package:surfpos_ai/features/inventory/widgets/product_image_picker.dart';

import '../fakes/fake_inventory_repository.dart';

const _uid = 'uid-merchant-a';

Widget _wrap(Widget child, {required Override inventoryOverride}) {
  return ProviderScope(
    overrides: [inventoryOverride],
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('shows a placeholder when no image is selected', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProductImagePicker(uid: _uid, onChanged: (_) {}),
        inventoryOverride: inventoryRepositoryProvider
            .overrideWithValue(FakeInventoryRepository()),
      ),
    );

    expect(find.text('No image selected'), findsOneWidget);
    expect(find.text('Remove Image'), findsNothing);
  });

  testWidgets(
      'picking from the gallery shows the preview and reports the new path',
      (tester) async {
    final tempFile =
        File('${Directory.systemTemp.path}/product_image_picker_test.jpg')
          ..writeAsBytesSync([0, 1, 2, 3]);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    String? reportedPath;
    await tester.pumpWidget(
      _wrap(
        ProductImagePicker(uid: _uid, onChanged: (path) => reportedPath = path),
        inventoryOverride: inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
              pickImageFromGallery: () async => tempFile.path),
        ),
      ),
    );

    await tester.tap(find.text('Select from Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('No image selected'), findsNothing);
    expect(reportedPath, tempFile.path);
  });

  testWidgets(
      'shows an inline error message when picking fails, without crashing',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProductImagePicker(uid: _uid, onChanged: (_) {}),
        inventoryOverride: inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            captureImageFromCamera: () async =>
                throw const ProductImageException('Camera access is denied.'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Camera access is denied.'), findsOneWidget);
  });

  testWidgets(
      'cancelling the picker (null result) leaves the existing image untouched',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProductImagePicker(
            uid: _uid,
            initialImagePath: '/tmp/existing.jpg',
            onChanged: (_) {}),
        inventoryOverride: inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(pickImageFromGallery: () async => null),
        ),
      ),
    );

    expect(find.text('Remove Image'), findsOneWidget);

    await tester.tap(find.text('Select from Gallery'));
    await tester.pumpAndSettle();

    // Still showing the Remove action for the pre-existing (now-missing-on-disk) image path —
    // proves the cancelled pick didn't clear it.
    expect(find.text('Remove Image'), findsOneWidget);
  });

  testWidgets('Remove Image clears the preview and reports null',
      (tester) async {
    String? reportedPath = 'unset';
    await tester.pumpWidget(
      _wrap(
        ProductImagePicker(
          uid: _uid,
          initialImagePath: '/tmp/existing.jpg',
          onChanged: (path) => reportedPath = path,
        ),
        inventoryOverride: inventoryRepositoryProvider
            .overrideWithValue(FakeInventoryRepository()),
      ),
    );

    await tester.tap(find.text('Remove Image'));
    await tester.pumpAndSettle();

    expect(find.text('No image selected'), findsOneWidget);
    expect(find.text('Remove Image'), findsNothing);
    expect(reportedPath, isNull);
  });
}
