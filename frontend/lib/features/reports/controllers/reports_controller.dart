import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_period.dart';
import '../models/reports_state.dart';
import '../providers/reports_providers.dart';

/// Loads the Reports dashboard snapshot for exactly one Firebase uid (see
/// [reportsControllerProvider] — a `.family` provider, the uid is this
/// notifier's `arg`). Mirrors [DashboardController]'s shape: `build()` does
/// the initial load (defaulting to [ReportPeriod.today]), [refresh]
/// re-runs it for the currently selected filter, and [changePeriod] is the
/// one additional entry point Reports needs — switching [ReportFilterBar]'s
/// selection re-fetches for the new filter.
class ReportsController
    extends AutoDisposeFamilyAsyncNotifier<ReportsState, String> {
  @override
  Future<ReportsState> build(String uid) async {
    const period = ReportPeriod.today;
    final snapshot = await ref
        .read(reportsRepositoryProvider(uid))
        .loadReports(period: period);
    return ReportsState(period: period, snapshot: snapshot);
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    final current = state.valueOrNull;
    final period = current?.period ?? ReportPeriod.today;
    final customRange = current?.customRange;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final snapshot = await ref
          .read(reportsRepositoryProvider(arg))
          .loadReports(period: period, customRange: customRange);
      return ReportsState(
          period: period, customRange: customRange, snapshot: snapshot);
    });
  }

  Future<void> changePeriod(ReportPeriod period,
      {DateTimeRange? customRange}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final snapshot = await ref
          .read(reportsRepositoryProvider(arg))
          .loadReports(period: period, customRange: customRange);
      return ReportsState(
          period: period, customRange: customRange, snapshot: snapshot);
    });
  }
}
