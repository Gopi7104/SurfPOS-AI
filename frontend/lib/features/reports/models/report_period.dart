/// The Reports date-range filter — drives every section on
/// [ReportsHomePage] via [ReportsRepository.loadReports]. [custom] is the
/// only variant that needs an explicit range (see [ReportsState.customRange]);
/// every other value is a fixed, self-describing window anchored on "now".
enum ReportPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  thisYear,
  custom;

  String get label => switch (this) {
        ReportPeriod.today => 'Today',
        ReportPeriod.yesterday => 'Yesterday',
        ReportPeriod.last7Days => '7 Days',
        ReportPeriod.last30Days => '30 Days',
        ReportPeriod.thisMonth => 'This Month',
        ReportPeriod.thisYear => 'This Year',
        ReportPeriod.custom => 'Custom',
      };
}
