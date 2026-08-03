import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/charts/mini_sparkline.dart';
import '../../../core/widgets/progress/app_progress_bar.dart';

/// The Key Metrics showcase — card "kinds" of varying size/emphasis
/// (Medium/Wide/Compact) replacing the old uniform [KpiCard]/[KpiGrid]
/// grid for Reports' hero KPI section specifically. [KpiCard]/[KpiGrid]
/// themselves are untouched and still back `InventoryHealthCard` — this
/// is a deliberately separate, new widget set so that section's look is
/// never affected by this one's redesign. The Highlight (Revenue) and
/// Pill (Refund Rate/Inventory Value) kinds this section used to include
/// were removed in Phase UI/UX 7 — Highlight duplicated the figure
/// `AnalyticsHeroHeader` already shows, and Pill was never backed by real
/// or demo data in the first place.
///
/// Every card shares the same rules: an icon in a soft tinted container, a
/// large bold animated value (or an honest "No data yet" state — never a
/// bare "—"/"Coming soon" inside a KPI card, per the redesign brief), a
/// small title, and a supporting insight line (falls back to "Updated just
/// now" when no specific insight applies). [AppCard]'s own onTap
/// press-scale gives every card its tap feedback; a no-op [VoidCallback] is
/// intentional — these cards report, they don't navigate.

const _kNoDataIcon = LucideIcons.circleDashed;

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.growth});

  final double growth;

  @override
  Widget build(BuildContext context) {
    final isUp = growth >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    final background =
        isUp ? AppColors.successContainer : AppColors.errorContainer;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.curve.enter,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 11,
                color: color),
            const SizedBox(width: 2),
            Text('${growth.abs().toStringAsFixed(0)}%',
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(
      {required this.icon,
      required this.color,
      required this.background,
      this.size = 40});

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Icon(icon, size: size * 0.45, color: color),
    );
  }
}

class _NoDataLine extends StatelessWidget {
  const _NoDataLine({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(_kNoDataIcon, size: 14, color: AppColors.disabledText),
        const SizedBox(width: 4),
        Text('No data yet',
            style: (compact ? AppTypography.caption : AppTypography.numberSM)
                .copyWith(color: AppColors.disabledText)),
      ],
    );
  }
}

/// A mid-emphasis card — bigger than Compact, smaller than Wide; used
/// for a metric that matters but shouldn't compete with the page's hero
/// figure.
class KpiMediumCard extends StatelessWidget {
  const KpiMediumCard({
    required this.label,
    required this.icon,
    this.value,
    this.formatter,
    this.growthPercent,
    this.insight,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;
  final IconData icon;
  final double? value;
  final String Function(double value)? formatter;
  final double? growthPercent;
  final String? insight;
  final Color iconColor;
  final Color iconBackground;

  bool get _hasData => value != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBadge(
                  icon: icon,
                  color: iconColor,
                  background: iconBackground,
                  size: 34),
              if (growthPercent != null) _TrendChip(growth: growthPercent!),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          _hasData
              ? CountUpNumber(
                  value: value!,
                  formatter: formatter ?? (v) => v.toStringAsFixed(0),
                  style: AppTypography.numberLG,
                )
              : const _NoDataLine(),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(insight ?? 'Updated just now',
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// The smallest full card — a compact square used for secondary figures
/// sitting side by side (e.g. Orders/Customers next to the Revenue
/// highlight).
class KpiCompactCard extends StatelessWidget {
  const KpiCompactCard({
    required this.label,
    required this.icon,
    this.value,
    this.formatter,
    this.insight,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;
  final IconData icon;
  final double? value;
  final String Function(double value)? formatter;
  final String? insight;
  final Color iconColor;
  final Color iconBackground;

  bool get _hasData => value != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
              icon: icon,
              color: iconColor,
              background: iconBackground,
              size: 28),
          const SizedBox(height: AppSpacing.sm),
          _hasData
              ? CountUpNumber(
                  value: value!,
                  formatter: formatter ?? (v) => v.toStringAsFixed(0),
                  style: AppTypography.numberSM,
                )
              : const _NoDataLine(compact: true),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (insight != null) ...[
            const SizedBox(height: 2),
            Text(insight!,
                style:
                    AppTypography.caption.copyWith(color: AppColors.textGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// A full-width row card pairing a headline figure with either a mini
/// sparkline or a horizontal progress indicator — used for metrics best
/// read alongside a trend shape (Average Order Value, Growth).
class KpiWideCard extends StatelessWidget {
  const KpiWideCard({
    required this.label,
    required this.icon,
    this.value,
    this.formatter,
    this.insight,
    this.sparklineValues = const [],
    this.progressValue,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;
  final IconData icon;
  final double? value;
  final String Function(double value)? formatter;
  final String? insight;

  /// A mini chart alongside the value.
  final List<double> sparklineValues;

  /// `0.0`–`1.0` — an alternative to [sparklineValues] for a metric better
  /// read as "how far along" (e.g. Growth). Only one of the two is ever
  /// shown; [sparklineValues] wins if both are supplied.
  final double? progressValue;
  final Color iconColor;
  final Color iconBackground;

  bool get _hasData => value != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBadge(
                  icon: icon,
                  color: iconColor,
                  background: iconBackground,
                  size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.bodySM
                            .copyWith(color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    _hasData
                        ? CountUpNumber(
                            value: value!,
                            formatter: formatter ?? (v) => v.toStringAsFixed(0),
                            style: AppTypography.numberLG,
                          )
                        : const _NoDataLine(),
                  ],
                ),
              ),
              if (_hasData && sparklineValues.length >= 2)
                SizedBox(
                    width: 96,
                    child: MiniSparkline(
                        values: sparklineValues, color: iconColor, height: 40)),
            ],
          ),
          if (_hasData &&
              sparklineValues.length < 2 &&
              progressValue != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            AppProgressBar(value: progressValue!, color: iconColor),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(insight ?? 'Updated just now',
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
