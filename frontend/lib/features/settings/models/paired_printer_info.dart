/// A Bluetooth-paired printer, as listed by [PrinterRepository]. This
/// module's own type — deliberately not Receipt's `PairedPrinterModel` —
/// since [PrinterRepository] talks to `print_bluetooth_thermal` directly
/// rather than depending on the Receipt feature at all (see
/// `PrinterRepository`'s header comment).
class PairedPrinterInfo {
  const PairedPrinterInfo({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}
