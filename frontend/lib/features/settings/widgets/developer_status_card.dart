import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/diagnostics_snapshot.dart';

/// A single diagnostic tile — status dot, latency, last-checked time, and
/// a refresh button. Backend/Surfboard/Firebase/Printer in the Developer
/// section each render through this one widget rather than four
/// near-identical bespoke cards.
class DeveloperStatusCard extends StatelessWidget {
  const DeveloperStatusCard({
    required this.title,
    required this.status,
    this.latency,
    this.lastChecked,
    this.onRefresh,
    this.isRefreshing = false,
    super.key,
  });

  final String title;
  final ServiceStatus status;
  final String? latency;
  final String? lastChecked;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  Color get _dotColor => switch (status) {
        ServiceStatus.connected => AppColors.success,
        ServiceStatus.disconnected => AppColors.error,
        ServiceStatus.unknown => AppColors.textGrey,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [
                    status.label,
                    if (latency != null) latency!,
                    if (lastChecked != null) 'Checked $lastChecked',
                  ].join(' · '),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            SizedBox(
              width: 36,
              height: 36,
              child: isRefreshing
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.refreshCw,
                          size: 16, color: AppColors.textGrey),
                      onPressed: onRefresh,
                    ),
            ),
        ],
      ),
    );
  }
}
