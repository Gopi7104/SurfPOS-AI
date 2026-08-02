import 'package:flutter/material.dart';

import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/diagnostics_snapshot.dart';
import 'settings_info_tile.dart';

/// A titled block of (label, [ServiceStatus]) rows — Backend/Surfboard/
/// Firebase in the Payment and Developer sections both render through
/// this one widget rather than three near-identical bespoke blocks.
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<(String label, ServiceStatus status)> entries;

  StatusTone _toneFor(ServiceStatus status) => switch (status) {
        ServiceStatus.connected => StatusTone.success,
        ServiceStatus.disconnected => StatusTone.error,
        ServiceStatus.unknown => StatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Column(
        children: [
          for (final entry in entries)
            SettingsInfoTile(
              label: entry.$1,
              trailing:
                  StatusChip(label: entry.$2.label, tone: _toneFor(entry.$2)),
            ),
        ],
      ),
    );
  }
}
