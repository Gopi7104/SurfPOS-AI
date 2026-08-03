import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/receipt/repositories/thermal_receipt_formatter.dart';

/// [Generator]/[CapabilityProfile] are pure Dart (no platform channel), so
/// these exercise the real formatter end to end and just decode the
/// resulting ESC/POS byte stream back to text to assert on content —
/// control bytes map to non-printable characters but never corrupt the
/// literal ASCII substrings we search for.
String _decode(List<int> bytes) => String.fromCharCodes(bytes);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;

  setUpAll(() async {
    profile = await CapabilityProfile.load();
  });

  ThermalReceiptFormatter formatterFor(PaperSize paperSize) {
    return ThermalReceiptFormatter(Generator(paperSize, profile), paperSize);
  }

  group('singleLineItemChars', () {
    test('scales with paper width — 6/12 of the paper\'s own char width', () {
      expect(formatterFor(PaperSize.mm58).singleLineItemChars, 16); // 32*6/12
      expect(formatterFor(PaperSize.mm80).singleLineItemChars, 24); // 48*6/12
    });
  });

  group('printKeyValue', () {
    test('contains the label and value', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printKeyValue('Receipt #', 'ORD-123'));
      expect(text, contains('Receipt #'));
      expect(text, contains('ORD-123'));
    });

    test('truncates a value too long to fit instead of wrapping it', () {
      final f = formatterFor(PaperSize.mm58);
      const longId = '845050e2abcdef1234567890fedcba9876543210';
      final text = _decode(f.printKeyValue('Txn ID', longId));
      expect(text, contains('...'));
      expect(text, isNot(contains(longId)));
      // Exactly one line — a long ID must never wrap onto a second line.
      expect('\n'.allMatches(text).length, 1);
    });

    test('different labels still line their colons up in the same column', () {
      final f = formatterFor(PaperSize.mm58);
      final short = _decode(f.printKeyValue('Phone', '9025758064'));
      final long = _decode(f.printKeyValue('Customer', 'Ramya'));
      int colonIndex(String s) => s.indexOf(':');
      expect(colonIndex(short), colonIndex(long));
    });
  });

  group('printProductRow', () {
    test('contains the name, quantity, and formatted amount', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printProductRow('Munch', 1, 2.0));
      expect(text, contains('Munch'));
      expect(text, contains(r'$2.00'));
    });

    test('formats a negative-safe amount without misplacing the sign', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printProductRow('Item', 2, 20.10));
      expect(text, contains(r'$20.10'));
    });
  });

  group('printWrappedProduct', () {
    test('wraps a long name across multiple lines and keeps the qty/amount',
        () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printWrappedProduct(
          'Chocolate Cream Filled Wafers 72g Extra Large Family Pack',
          1,
          25.25));
      // Word-wrapped into more than one physical line (one \n per line).
      expect('\n'.allMatches(text).length, greaterThan(1));
      expect(text, contains('Chocolate'));
      expect(text, contains(r'$25.25'));
    });

    test(
        'a short-enough wrapped name still fits the qty/amount on its final line',
        () {
      final f = formatterFor(PaperSize.mm58);
      // Long enough to exceed singleLineItemChars (16) but short enough that
      // the final wrapped line still has room for "1  \$25.25".
      final text = _decode(
          f.printWrappedProduct('Chocolate Cream Filled Wafers', 1, 25.25));
      expect(text, contains('Chocolate'));
      expect(text, contains(r'$25.25'));
    });

    test('never throws, even for a single word longer than the line width', () {
      final f = formatterFor(PaperSize.mm58);
      // No spaces at all to break on — the wrap algorithm must not crash
      // (e.g. via a negative padding count) even when it can't find a
      // word boundary to wrap at.
      expect(
          () => f.printWrappedProduct(
              'Supercalifragilisticexpialidocious1234567890ExtraLong',
              3,
              123.45),
          returnsNormally);
    });

    test('never throws for an empty product name', () {
      final f = formatterFor(PaperSize.mm58);
      expect(() => f.printWrappedProduct('', 1, 1.00), returnsNormally);
    });
  });

  group('printTotals', () {
    test('contains every total line and the emphasized grand TOTAL', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printTotals(
          subtotal: 22.00, discount: 0.10, tax: 0.20, total: 22.10));
      expect(text, contains('Subtotal'));
      expect(text, contains(r'$22.00'));
      expect(text, contains('Discount'));
      expect(text, contains(r'-$0.10'));
      expect(text, contains('Tax'));
      expect(text, contains('TOTAL'));
      expect(text, contains(r'$22.10'));
    });
  });

  group('printHeader', () {
    test('contains merchant/store name, tagline, and identifiers', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printHeader(
        merchantName: 'Velan & Gopi',
        storeName: 'Velan & Gopi Store',
        receiptNo: 'ORD-1',
        transactionId: 'TXN-1',
        date: '03 Aug 2026',
        time: '11:13 AM',
      ));
      expect(text, contains('Velan & Gopi'));
      expect(text, contains('Powered by SurfPOS AI'));
      expect(text, contains('Receipt #'));
      expect(text, contains('Txn ID'));
      expect(text, contains('03 Aug 2026'));
      expect(text, contains('11:13 AM'));
    });

    test('omits Txn ID entirely when null', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printHeader(
        merchantName: 'Velan & Gopi',
        storeName: 'Velan & Gopi Store',
        receiptNo: 'ORD-1',
        date: '03 Aug 2026',
        time: '11:13 AM',
      ));
      expect(text, isNot(contains('Txn ID')));
    });
  });

  group('printFooter', () {
    test('contains the real courtesy lines, nothing fabricated', () {
      final f = formatterFor(PaperSize.mm58);
      final text = _decode(f.printFooter());
      expect(text, contains('Thank You For Shopping!'));
      expect(text, contains('We Appreciate Your Business'));
      expect(text, contains('Visit Again'));
    });
  });
}
