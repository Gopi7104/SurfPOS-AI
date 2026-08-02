import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/paired_printer_info.dart';
import '../models/printer_config.dart';
import '../providers/settings_providers.dart';
import '../widgets/printer_status_card.dart';
import '../widgets/settings_info_tile.dart';

/// Pair, connect, and test a Bluetooth thermal printer, plus Paper Size —
/// the Printer section's dedicated page. See `PrinterRepository`'s header
/// comment for why this talks to `print_bluetooth_thermal` directly
/// rather than through Receipt.
class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() =>
      _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  PrinterConnectionStatus _status = PrinterConnectionStatus.checking;
  String? _connectedName;
  List<PairedPrinterInfo> _printers = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _status = PrinterConnectionStatus.checking);
    final repository = ref.read(printerRepositoryProvider);
    final printers = await repository.pairedPrinters();
    final connected = await repository.isConnected();
    if (!mounted) return;
    setState(() {
      _printers = printers;
      _status = connected
          ? PrinterConnectionStatus.connected
          : PrinterConnectionStatus.notConnected;
    });
  }

  Future<void> _connect(PairedPrinterInfo printer) async {
    final connected =
        await ref.read(printerRepositoryProvider).connect(printer.macAddress);
    if (!mounted) return;
    setState(() {
      _status = connected
          ? PrinterConnectionStatus.connected
          : PrinterConnectionStatus.error;
      _connectedName = connected ? printer.name : null;
    });
  }

  Future<void> _testPrint(PrinterPaperSize paperSize) async {
    setState(() => _status = PrinterConnectionStatus.testing);
    try {
      await ref.read(printerRepositoryProvider).testPrint(paperSize);
      if (!mounted) return;
      setState(() => _status = PrinterConnectionStatus.connected);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test page sent to the printer.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = PrinterConnectionStatus.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not print a test page: $error')),
      );
    }
  }

  Future<void> _selectPaperSize(String uid, PrinterPaperSize current) async {
    final picked = await showModalBottomSheet<PrinterPaperSize>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final size in PrinterPaperSize.values)
              ListTile(
                title: Text(size.label),
                trailing: size == current
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(size),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref
          .read(settingsControllerProvider(uid).notifier)
          .updatePrinterPaperSize(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    final settings = uid == null
        ? null
        : ref.watch(settingsControllerProvider(uid)).valueOrNull;
    final paperSize = settings?.printerPaperSize ?? PrinterPaperSize.mm58;

    return Scaffold(
      appBar: AppTopBar(
          title: 'Printer', onBack: () => Navigator.of(context).pop()),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            PrinterStatusCard(
                status: _status, connectedPrinterName: _connectedName),
            const SizedBox(height: AppSpacing.sm + 2),
            SectionCard(
              title: 'Paired Printers',
              child: _printers.isEmpty
                  ? Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text('No paired Bluetooth printers found.',
                          style: AppTypography.bodySM),
                    )
                  : Column(
                      children: [
                        for (final printer in _printers)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(printer.name),
                            subtitle: Text(printer.macAddress),
                            trailing: TextButton(
                              onPressed: () => _connect(printer),
                              child: const Text('Connect'),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            if (uid != null)
              SectionCard(
                title: 'Paper',
                child: Column(
                  children: [
                    SettingsInfoTile(
                      label: 'Paper Size',
                      trailing: TextButton(
                        onPressed: () => _selectPaperSize(uid, paperSize),
                        child: Text(paperSize.label),
                      ),
                    ),
                    SettingsInfoTile(
                      label: 'Receipt Width',
                      value: '${paperSize.charactersPerLine} characters',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Print Test Page',
              isLoading: _status == PrinterConnectionStatus.testing,
              onPressed: _status == PrinterConnectionStatus.connected
                  ? () => _testPrint(paperSize)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
