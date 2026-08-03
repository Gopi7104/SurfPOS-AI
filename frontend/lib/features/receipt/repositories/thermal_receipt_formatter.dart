import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// A reusable receipt layout engine — named formatting helpers over
/// [Generator]'s raw `text`/`row`/`hr` calls, used by
/// [ReceiptRepositoryImpl.printReceipt] so the receipt-building code reads
/// as a receipt layout (header, products, totals, footer) instead of
/// manual space-concatenation.
///
/// Every method derives its spacing from [paperSize] (via [_charsPerLine],
/// the same 32/42/48 Font-A character-width convention [Generator] itself
/// uses internally) or from [PosColumn]'s own 1..12 proportional widths —
/// nothing here hardcodes a character count, so the exact same calls
/// format correctly on 58mm and 80mm paper.
class ThermalReceiptFormatter {
  const ThermalReceiptFormatter(this._generator, this.paperSize);

  final Generator _generator;
  final PaperSize paperSize;

  /// A hanging hyphen-free indent prefixed to a wrapped product name's
  /// continuation lines (see [printWrappedProduct]) so they read as part
  /// of the item above rather than a new line item.
  static const _wrapIndent = '  ';

  /// Font-A characters-per-line for [paperSize] — the same convention
  /// [Generator] computes internally (`_getMaxCharsPerLine`), duplicated
  /// here only because that method isn't exposed publicly. This app never
  /// sets a font other than the default (Font A), so that's the only case
  /// handled.
  int get _charsPerLine => switch (paperSize) {
        PaperSize.mm58 => 32,
        PaperSize.mm72 => 42,
        _ => 48,
      };

  /// How many characters an item name can use on one line before
  /// [printWrappedProduct] is needed instead — the name column's own share
  /// (6 of 12 width units, matching [printProductRow]) of the paper's
  /// character width.
  int get singleLineItemChars => (_charsPerLine * 6 / 12).floor();

  // ***** Atomic helpers *****

  /// Centered text — `bold`/`doubleSize` are used for the merchant name
  /// and other emphasized lines.
  List<int> printCentered(
    String text, {
    bool bold = false,
    bool doubleSize = false,
  }) {
    return _generator.text(
      text,
      styles: PosStyles(
        align: PosAlign.center,
        bold: bold,
        height: doubleSize ? PosTextSize.size2 : PosTextSize.size1,
        width: doubleSize ? PosTextSize.size2 : PosTextSize.size1,
      ),
    );
  }

  /// A full-width divider rule — `heavy` switches from a thin `-` rule
  /// (used between minor sections) to a `=` rule (used around the header
  /// block and the grand TOTAL). Length always comes from the generator's
  /// own configured paper width.
  List<int> printDivider({bool heavy = false}) {
    return _generator.hr(ch: heavy ? '=' : '-');
  }

  /// The label column's fixed width for [printKeyValue] — every label this
  /// template actually uses (`Receipt #`, `Txn ID`, `Date`, `Time`,
  /// `Customer`, `Phone`, `Payment`, `Status`, `Ref No`, `Approval`) is 9
  /// characters or fewer, so every "Label: value" line in the receipt
  /// lines its colon up in the same column.
  static const _keyValueLabelWidth = 9;

  /// One label/value pair on a single compact line — `Label   : value`,
  /// label padded to [_keyValueLabelWidth] so every key-value line's colon
  /// (and therefore every value) starts in the same column. A value too
  /// long to fit is truncated with `...` rather than wrapped onto a second
  /// line — an ID/reference number must never wrap or float a later
  /// section's alignment out of place.
  List<int> printKeyValue(String label, String value,
      {bool boldValue = false}) {
    final prefix = '${label.padRight(_keyValueLabelWidth)}: ';
    final maxValueChars = _charsPerLine - prefix.length;
    return _generator.text(
      '$prefix${_truncate(value, maxValueChars)}',
      styles: PosStyles(bold: boldValue),
    );
  }

  /// `value` unchanged if it already fits `maxChars`, otherwise cut short
  /// with a trailing `...` (never a mid-word wrap) — e.g. a long generated
  /// order ID becomes `845050e2...`.
  String _truncate(String value, int maxChars) {
    if (value.length <= maxChars) return value;
    if (maxChars <= 3) {
      return value.substring(0, maxChars.clamp(0, value.length));
    }
    return '${value.substring(0, maxChars - 3)}...';
  }

  /// A bold, centered section banner — available for any part of the
  /// template that needs stronger emphasis than [printCentered] alone
  /// (used by [printFooter]'s opening line).
  List<int> printSectionTitle(String title) {
    return printCentered(title, bold: true);
  }

  // ***** Product table *****

  /// The product table's column header row (`ITEM | QTY | AMOUNT`), bold,
  /// same 6/2/4 column proportions [printProductRow]/[printWrappedProduct]
  /// use, so header and rows always line up.
  List<int> printProductTableHeader() {
    const styles = PosStyles(bold: true);
    return _generator.row([
      PosColumn(text: 'ITEM', width: 6, styles: styles),
      PosColumn(
          text: 'QTY',
          width: 2,
          styles: styles.copyWith(align: PosAlign.center)),
      PosColumn(
          text: 'AMOUNT',
          width: 4,
          styles: styles.copyWith(align: PosAlign.right)),
    ]);
  }

  /// One product line for a name that fits [singleLineItemChars] — a
  /// single `ITEM | QTY | AMOUNT` row, columns proportional so they never
  /// overlap regardless of paper width. Same 6/2/4 column widths as
  /// [printProductTableHeader] and the shared row [printWrappedProduct]
  /// builds, so quantity never floats and amount never shifts left
  /// relative to any other row on the receipt.
  List<int> printProductRow(String name, int quantity, double lineTotal) {
    return _productRow(name, quantity, lineTotal);
  }

  List<int> _productRow(String name, int quantity, double lineTotal) {
    return _generator.row([
      PosColumn(text: name, width: 6),
      PosColumn(
          text: '$quantity',
          width: 2,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: _money(lineTotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
  }

  /// A product line whose name is too long for [printProductRow] — the
  /// name word-wraps across as many lines as it needs (continuation lines
  /// get a hanging [_wrapIndent], so they read as part of the item above,
  /// never starting at column 1 like a new line item), and the *last*
  /// wrapped line always carries the qty/amount, printed via [_productRow]
  /// — the exact same [PosColumn] proportions every other product row
  /// uses, never a hand-padded string, so the qty/amount columns line up
  /// perfectly with every other row regardless of how the name wrapped.
  List<int> printWrappedProduct(String name, int quantity, double lineTotal) {
    final bytes = <int>[];
    final lines = _wrapToFit(name);

    for (var i = 0; i < lines.length - 1; i++) {
      final isFirstLine = i == 0;
      bytes.addAll(
          _generator.text(isFirstLine ? lines[i] : '$_wrapIndent${lines[i]}'));
    }

    final isOnlyLine = lines.length == 1;
    final lastLine = isOnlyLine ? lines.last : '$_wrapIndent${lines.last}';
    bytes.addAll(_productRow(lastLine, quantity, lineTotal));
    return bytes;
  }

  /// Word-wraps [text] so every line fits the paper's full width, *except*
  /// the last line, which must additionally fit [singleLineItemChars] (the
  /// item table's own name-column width) so it can share its row with
  /// qty/amount via [_productRow]. Trailing words are moved off the last
  /// line, one at a time, until it's narrow enough — this is what lets an
  /// early line like "Chocolate Cream Filled" use nearly the full width
  /// while the shared last line stays within its column.
  List<String> _wrapToFit(String text) {
    final words = text.isEmpty ? [''] : text.split(' ');
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      final isFirstLine = lines.isEmpty;
      final available =
          isFirstLine ? _charsPerLine : _charsPerLine - _wrapIndent.length;
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= available) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }
    lines.add(current);

    while (lines.last.length > singleLineItemChars) {
      final tail = lines.last.split(' ');
      if (tail.length == 1) break; // a single word too long even alone —
      // let Generator's own overflow handling wrap it, never crash.
      final moved = tail.removeLast();
      lines[lines.length - 1] = tail.join(' ');
      lines.add(moved);
    }
    return lines;
  }

  // ***** Composed sections *****

  /// The header block: centered merchant name (bold, double-size), store
  /// name, "Powered by SurfPOS AI" tagline, then the compact Receipt #/
  /// Txn ID/Date/Time identifiers — all real fields, one line each, no
  /// blank-line padding between them. Thin dividers only — the heavy rule
  /// is reserved for the grand TOTAL (see [printTotals]).
  List<int> printHeader({
    required String merchantName,
    required String storeName,
    required String receiptNo,
    String? transactionId,
    required String date,
    required String time,
  }) {
    final bytes = <int>[];
    bytes.addAll(printCentered(merchantName, bold: true, doubleSize: true));
    bytes.addAll(printCentered(storeName));
    bytes.addAll(printCentered('Powered by SurfPOS AI'));
    bytes.addAll(printDivider());
    bytes.addAll(printKeyValue('Receipt #', receiptNo));
    if (transactionId != null) {
      bytes.addAll(printKeyValue('Txn ID', transactionId));
    }
    bytes.addAll(printKeyValue('Date', date));
    bytes.addAll(printKeyValue('Time', time));
    bytes.addAll(printDivider());
    return bytes;
  }

  /// Subtotal/Discount/Tax as compact aligned rows, then the grand TOTAL
  /// set apart with a heavy rule and printed centered/bold/double-size —
  /// the strongest visual emphasis on the receipt, as requested.
  List<int> printTotals({
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) {
    final bytes = <int>[];
    bytes.addAll(_totalRow('Subtotal', subtotal));
    bytes.addAll(_totalRow('Discount', -discount));
    bytes.addAll(_totalRow('Tax', tax));
    bytes.addAll(printDivider(heavy: true));
    bytes.addAll(printCentered('TOTAL', bold: true, doubleSize: true));
    bytes.addAll(printCentered(_money(total), bold: true, doubleSize: true));
    bytes.addAll(printDivider(heavy: true));
    return bytes;
  }

  List<int> _totalRow(String label, double amount) {
    return _generator.row([
      PosColumn(text: label, width: 8),
      PosColumn(
          text: _money(amount),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
  }

  /// The closing block — real, non-fabricated courtesy text only (no
  /// invented contact/social/website details; see
  /// [ReceiptRepositoryImpl.printReceipt]'s header comment for why).
  List<int> printFooter() {
    final bytes = <int>[];
    bytes.addAll(printSectionTitle('Thank You For Shopping!'));
    bytes.addAll(printCentered('We Appreciate Your Business'));
    bytes.addAll(printCentered('Visit Again'));
    return bytes;
  }

  /// `-$0.10` for a negative amount (sign before the currency symbol),
  /// `$22.10` otherwise.
  String _money(double amount) {
    return amount < 0
        ? '-\$${(-amount).toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(2)}';
  }
}
