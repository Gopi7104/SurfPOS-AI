import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_line_item.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_model.dart';
import 'package:surfpos_ai/features/receipt/repositories/receipt_repository_impl.dart';

// print_bluetooth_thermal talks to native code over this MethodChannel (see
// its own lib/print_bluetooth_thermal.dart) — `flutter test` has no native
// binding, so these tests install a mock handler and exercise the real
// ReceiptRepositoryImpl against it, the same "real implementation, faked
// platform boundary" approach the payments feature uses for its HTTP client.
const _channel = MethodChannel('groons.web.app/print');

final _receipt = ReceiptModel(
  merchantName: 'Acme Surf Co',
  storeName: 'Downtown',
  orderId: 'order-1',
  paymentId: 'pay-1',
  transactionId: 'txn-1',
  completedAt: DateTime(2026, 1, 1, 12, 30),
  items: const [
    ReceiptLineItem(
        productName: 'Widget', quantity: 2, unitPrice: 10, lineTotal: 20),
  ],
  subtotal: 20,
  discountTotal: 0,
  taxTotal: 2,
  total: 22,
  paymentMethod: 'CARD',
  paymentStatus: 'Successful',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = ReceiptRepositoryImpl();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  void mockChannel(Map<String, Object? Function(MethodCall)> handlers) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      final handler = handlers[call.method];
      if (handler == null) {
        throw MissingPluginException('No handler for ${call.method}');
      }
      return handler(call);
    });
  }

  group('buildReceiptPdf', () {
    test('produces a non-empty PDF byte stream', () async {
      final bytes = await repository.buildReceiptPdf(_receipt);
      expect(bytes, isNotEmpty);
      // %PDF is the standard PDF file signature.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('pairedPrinters', () {
    test('returns paired devices when Bluetooth permission is granted',
        () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'pairedbluetooths': (_) => ['Front Counter#AA:BB:CC:DD:EE:FF'],
      });

      final printers = await repository.pairedPrinters();

      expect(printers, hasLength(1));
      expect(printers.single.name, 'Front Counter');
      expect(printers.single.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('returns an empty list when Bluetooth permission is denied', () async {
      mockChannel({'ispermissionbluetoothgranted': (_) => false});

      final printers = await repository.pairedPrinters();

      expect(printers, isEmpty);
    });
  });

  group('connect / isConnected', () {
    test('connect() reports the native connect result', () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'connect': (_) => true,
      });
      expect(await repository.connect('AA:BB:CC:DD:EE:FF'), isTrue);
    });

    test('isConnected() reports the native connection status', () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'connectionstatus': (_) => true,
      });
      expect(await repository.isConnected(), isTrue);
    });

    // Regression coverage: `connectionstatus`/`connect` hang forever (no
    // platform-channel reply at all) when called while Bluetooth permission
    // is missing — see this file's header comment. Never registering a
    // handler for them here proves these calls short-circuit on the
    // permission check and never reach the native side while denied.
    test(
        'connect() returns false without touching the native side when permission is denied',
        () async {
      mockChannel({'ispermissionbluetoothgranted': (_) => false});
      expect(await repository.connect('AA:BB:CC:DD:EE:FF'), isFalse);
    });

    test(
        'isConnected() returns false without touching the native side when permission is denied',
        () async {
      mockChannel({'ispermissionbluetoothgranted': (_) => false});
      expect(await repository.isConnected(), isFalse);
    });
  });

  group('printReceipt', () {
    test('throws without touching the native side when permission is denied',
        () async {
      mockChannel({'ispermissionbluetoothgranted': (_) => false});

      expect(
          () => repository.printReceipt(_receipt), throwsA(isA<StateError>()));
    });

    test('throws when no printer is connected', () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'connectionstatus': (_) => false,
      });

      expect(
          () => repository.printReceipt(_receipt), throwsA(isA<StateError>()));
    });

    test('writes ESC/POS bytes when connected and the printer accepts them',
        () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'connectionstatus': (_) => true,
        'writebytes': (_) => true,
      });

      await repository.printReceipt(_receipt);
    });

    test('throws when the printer rejects the bytes', () async {
      mockChannel({
        'ispermissionbluetoothgranted': (_) => true,
        'connectionstatus': (_) => true,
        'writebytes': (_) => false,
      });

      expect(
          () => repository.printReceipt(_receipt), throwsA(isA<StateError>()));
    });
  });
}
