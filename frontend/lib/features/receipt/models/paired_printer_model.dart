/// A Bluetooth-paired printer, as listed for the "Connect Printer" picker —
/// mirrors `print_bluetooth_thermal`'s own `BluetoothInfo`, kept as this
/// app's own type so nothing outside `ReceiptRepositoryImpl` depends on that
/// package directly (see `ReceiptRepository`'s header comment).
class PairedPrinterModel {
  const PairedPrinterModel({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}
