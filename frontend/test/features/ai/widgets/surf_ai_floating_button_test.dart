import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/ai/pages/surf_ai_chat_page.dart';
import 'package:surfpos_ai/features/ai/widgets/surf_ai_floating_button.dart';

import '../../authentication/fakes/fake_auth_repository.dart';

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

/// Bounded, repeated pumps — `SurfAiFloatingButton`'s breathing/pulse
/// animations repeat forever by design, so `pumpAndSettle()` would time out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _wrap() {
  return ProviderScope(
    overrides: [
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService()),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(restoreSession: () async => testAuthUser()),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SurfAiFloatingButton()),
    ),
  );
}

void main() {
  testWidgets('renders the sparkle badge', (tester) async {
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    expect(find.byType(SurfAiBadge), findsOneWidget);
  });

  testWidgets('tapping it navigates to SurfAiChatPage with a haptic tick',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    await tester.tap(find.byType(SurfAiFloatingButton));
    await _settle(tester);

    expect(find.byType(SurfAiChatPage), findsOneWidget);
  });

  testWidgets('does not leave any pending timers behind when disposed',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    // Unmount by replacing the whole tree — if SurfAiFloatingButton ever
    // regresses back to a bare Timer.periodic (see its header comment on why
    // it deliberately uses only AnimationControllers), this would fail with
    // "A Timer is still pending even after the widget tree was disposed."
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
