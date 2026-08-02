/// State of the Bluetooth ESC/POS thermal printer connection, as understood
/// by the Receipt screen — see `ReceiptController.checkPrinter`/`printReceipt`.
enum PrinterStatus {
  /// Not checked yet (initial state before the Receipt screen's first check).
  unknown,
  checking,

  /// A paired printer was found and is connected — Print Receipt runs
  /// automatically, per the spec's "if a Bluetooth printer is already
  /// paired, print automatically".
  connected,

  /// No paired printer found — the screen shows "No printer connected"
  /// with Connect Printer / Skip actions.
  notConnected,
  printing,
  printed,
  error,
}
