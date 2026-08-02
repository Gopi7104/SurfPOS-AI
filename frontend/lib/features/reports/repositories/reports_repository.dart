import 'package:flutter/material.dart' show DateTimeRange;

import '../models/report_period.dart';
import '../models/reports_snapshot.dart';

/// Seam between [ReportsController] and wherever Reports data actually
/// comes from — mirrors `DashboardRepository`/`InventoryRepository`. Local-
/// data-only for now (see [ReportsRepositoryImpl]'s header comment); no
/// `/reports` backend endpoint exists yet.
abstract class ReportsRepository {
  /// [customRange] is only read when [period] is [ReportPeriod.custom].
  Future<ReportsSnapshot> loadReports({
    required ReportPeriod period,
    DateTimeRange? customRange,
  });
}
