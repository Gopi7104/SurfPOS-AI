import 'dart:math';

/// Fake payment-specific fields for the development-only Test Payment flow
/// (see `TestPaymentRepository`) — never sent to or received from any
/// backend. Only [paymentId]/[transactionId]/[reference] feed into the
/// shared [ReceiptModel] (via its existing fields); [receiptNumber] and
/// [approvalCode] are shown on the Test Payment status screen itself so
/// every generated value the spec asks for is visible somewhere, without
/// adding test-only fields to the real receipt model.
class TestPaymentResult {
  const TestPaymentResult({
    required this.paymentId,
    required this.transactionId,
    required this.receiptNumber,
    required this.approvalCode,
    required this.reference,
    required this.timestamp,
  });

  final String paymentId;
  final String transactionId;
  final String receiptNumber;
  final String approvalCode;
  final String reference;
  final DateTime timestamp;

  static const method = 'TEST CARD';
  static const status = 'SUCCESS';
  static const currency = 'SEK';

  factory TestPaymentResult.generate() {
    final now = DateTime.now();
    return TestPaymentResult(
      paymentId: 'PAY-${_randomAlphanumeric(8)}',
      transactionId: 'TXN-${_randomAlphanumeric(8)}',
      receiptNumber: 'RCP-${_randomAlphanumeric(8)}',
      approvalCode: _randomDigits(6),
      reference: 'TEST-${_yyyymmdd(now)}-${_hhmmss(now)}',
      timestamp: now,
    );
  }

  static const _alphanumeric = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static String _randomAlphanumeric(int length) {
    final random = Random();
    return List.generate(
            length, (_) => _alphanumeric[random.nextInt(_alphanumeric.length)])
        .join();
  }

  static String _randomDigits(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _yyyymmdd(DateTime dt) =>
      '${dt.year}${_twoDigits(dt.month)}${_twoDigits(dt.day)}';

  static String _hhmmss(DateTime dt) =>
      '${_twoDigits(dt.hour)}${_twoDigits(dt.minute)}${_twoDigits(dt.second)}';
}
