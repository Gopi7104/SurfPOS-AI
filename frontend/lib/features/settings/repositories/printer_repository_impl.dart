import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/paired_printer_info.dart';
import '../models/printer_config.dart';
import 'printer_repository.dart';

/// Talks to `print_bluetooth_thermal`/`esc_pos_utils_plus` directly, the
/// same two packages Receipt's own (separate, untouched) printing uses —
/// deliberately **not** built on `ReceiptRepository`: this module manages
/// and tests a printer connection as its own concern (Settings' Printer
/// section), Receipt prints a specific completed sale as its concern.
/// Depending on Receipt's repository/controller for that would couple a
/// restricted feature's internals to Settings for no real benefit, since
/// the two need different things from the same underlying package.
class PrinterRepositoryImpl implements PrinterRepository {
  @override
  Future<List<PairedPrinterInfo>> pairedPrinters() async {
    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) return [];

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return [
      for (final device in devices)
        PairedPrinterInfo(name: device.name, macAddress: device.macAdress),
    ];
  }

  @override
  Future<bool> connect(String macAddress) {
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  @override
  Future<bool> isConnected() => PrintBluetoothThermal.connectionStatus;

  @override
  Future<void> testPrint(PrinterPaperSize paperSize) async {
    final connected = await isConnected();
    if (!connected) {
      throw StateError('No printer connected.');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == PrinterPaperSize.mm80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    final bytes = <int>[];

    bytes.addAll(generator.text(
      'SurfPOS AI',
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text('Printer Test Page',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Paper size: ${paperSize.label}'));
    bytes.addAll(
        generator.text('Characters per line: ${paperSize.charactersPerLine}'));
    bytes.addAll(generator.text(DateTime.now().toString()));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('If you can read this, your printer',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.text('is connected and working correctly.',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final written = await PrintBluetoothThermal.writeBytes(bytes);
    if (!written) {
      throw StateError('The printer did not accept the test page.');
    }
  }
}
