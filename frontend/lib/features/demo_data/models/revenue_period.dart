/// The Revenue Chart's interactive Today/Week/Month toggle.
enum RevenuePeriod {
  today,
  week,
  month;

  String get label => switch (this) {
        RevenuePeriod.today => 'Today',
        RevenuePeriod.week => 'Week',
        RevenuePeriod.month => 'Month',
      };
}
