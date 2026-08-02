import 'package:flutter/material.dart' show DateTimeRange;

import 'report_period.dart';
import 'reports_snapshot.dart';

/// [ReportsController]'s state — the currently selected filter alongside
/// the [ReportsSnapshot] it produced. Kept together (rather than the
/// snapshot alone) so [ReportFilterBar] always reflects the filter that's
/// actually loaded, including across a hot-restart or a `refresh()`.
class ReportsState {
  const ReportsState({
    required this.period,
    this.customRange,
    required this.snapshot,
  });

  final ReportPeriod period;

  /// Only meaningful when [period] is [ReportPeriod.custom].
  final DateTimeRange? customRange;
  final ReportsSnapshot snapshot;

  ReportsState copyWith({
    ReportPeriod? period,
    DateTimeRange? customRange,
    ReportsSnapshot? snapshot,
  }) {
    return ReportsState(
      period: period ?? this.period,
      customRange: customRange ?? this.customRange,
      snapshot: snapshot ?? this.snapshot,
    );
  }
}
