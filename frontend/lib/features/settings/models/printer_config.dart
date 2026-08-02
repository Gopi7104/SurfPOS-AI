/// Thermal-printer paper widths — mirrors the two sizes
/// `esc_pos_utils_plus`'s `PaperSize` enum supports, which is what
/// [PrinterRepository.testPrint] and Receipt's own (separate, untouched)
/// printing both build ESC/POS bytes for.
enum PrinterPaperSize {
  mm58,
  mm80;

  String get label => switch (this) {
        PrinterPaperSize.mm58 => '58mm',
        PrinterPaperSize.mm80 => '80mm',
      };

  /// Characters per line at this width, for a standard thermal font —
  /// what "Receipt Width" actually configures.
  int get charactersPerLine => switch (this) {
        PrinterPaperSize.mm58 => 32,
        PrinterPaperSize.mm80 => 48,
      };
}

/// Live state of [PrinterRepository]'s Bluetooth connection — this
/// module's own analog of Receipt's `PrinterStatus`, kept separate since
/// Settings manages/tests the printer connection itself rather than
/// printing a receipt (a different responsibility; see
/// `PrinterRepository`'s header comment for why this doesn't reuse
/// Receipt's repository).
enum PrinterConnectionStatus {
  checking,
  connected,
  notConnected,
  testing,
  error;

  String get label => switch (this) {
        PrinterConnectionStatus.checking => 'Checking…',
        PrinterConnectionStatus.connected => 'Connected',
        PrinterConnectionStatus.notConnected => 'No printer connected',
        PrinterConnectionStatus.testing => 'Printing test page…',
        PrinterConnectionStatus.error => 'Connection error',
      };
}
