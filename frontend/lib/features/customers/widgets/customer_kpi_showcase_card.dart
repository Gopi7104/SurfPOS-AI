import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/app_card.dart';

/// The Customer Overview showcase — five card "kinds" of varying size/
/// emphasis (Highlight/Medium/Wide/Compact/Pill), replacing the old
/// uniform [CustomerKpiCard]/[CustomerKpiGrid] grid. A Customers-local
/// twin of Reports' `kpi_showcase_card.dart` (same visual language, kept
/// feature-local per this app's established per-feature widget
/// convention — see e.g. `CustomerSummaryCard`/`SummaryCard`).
///
/// Every card shares the same rules: an icon in a soft tinted container, a
/// large bold animated value (or an honest "No data yet" state — never a
/// bare "—"/"Coming soon" inside a KPI card), a small title, and a
/// supporting insight line (falls back to "Updated just now"). [AppCard]'s
/// own onTap press-scale gives every card its tap feedback; a no-op
/// [VoidCallback] is intentional — these cards report, they don't
/// navigate.

const _kNoDataIcon = LucideIcons.circleDashed;

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

class _AccentLine extends StatelessWidget {
  const _AccentLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [color, color.withValues(alpha: 0.25)]),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
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

/// The single most important figure on the page (Total Customers) — full
/// width, elevated shadow, a gradient accent line, a soft "glass" sheen
/// overlay, and an animated headline number.
class CustomerKpiHighlightCard extends StatelessWidget {
  const CustomerKpiHighlightCard({
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
      elevated: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white.withValues(alpha: 0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AccentLine(color: iconColor),
              const SizedBox(height: AppSpacing.sm),
              _IconBadge(
                  icon: icon, color: iconColor, background: iconBackground),
              const SizedBox(height: AppSpacing.md),
              _hasData
                  ? CountUpNumber(
                      value: value!,
                      formatter: formatter ?? (v) => v.toStringAsFixed(0),
                      style: AppTypography.numberXL,
                    )
                  : const _NoDataLine(),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                insight ?? 'Updated just now',
                style:
                    AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A mid-emphasis card — bigger than Compact, smaller than Highlight.
class CustomerKpiMediumCard extends StatelessWidget {
  const CustomerKpiMediumCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
              icon: icon,
              color: iconColor,
              background: iconBackground,
              size: 34),
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
/// sitting side by side.
class CustomerKpiCompactCard extends StatelessWidget {
  const CustomerKpiCompactCard({
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

/// A full-width row card — used for a metric best read at a glance
/// alongside its icon (Average Spend).
class CustomerKpiWideCard extends StatelessWidget {
  const CustomerKpiWideCard({
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
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(insight ?? 'Updated just now',
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The most minimal representation — a single-line pill, used for
/// secondary or currently-unavailable metrics (Lifetime Revenue, Inactive
/// Customers) that don't deserve a full card's worth of space.
class CustomerKpiStatPill extends StatelessWidget {
  const CustomerKpiStatPill({
    required this.label,
    required this.icon,
    this.value,
    this.formatter,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;
  final IconData icon;
  final double? value;
  final String Function(double value)? formatter;
  final Color iconColor;
  final Color iconBackground;

  bool get _hasData => value != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
              icon: icon,
              color: iconColor,
              background: iconBackground,
              size: 24),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypography.caption),
              _hasData
                  ? CountUpNumber(
                      value: value!,
                      formatter: formatter ?? (v) => v.toStringAsFixed(0),
                      style: AppTypography.bodySM
                          .copyWith(fontWeight: FontWeight.w700),
                    )
                  : Text('No data yet',
                      style: AppTypography.bodySM.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.disabledText)),
            ],
          ),
        ],
      ),
    );
  }
}
