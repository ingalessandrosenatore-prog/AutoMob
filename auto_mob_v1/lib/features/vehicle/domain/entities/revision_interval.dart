enum RevisionInterval {
  sixMonths(6),
  oneYear(12),
  twoYears(24),
  fourYears(48);

  final int months;

  const RevisionInterval(this.months);

  DateTime dateFrom(DateTime start) {
    final targetMonth = start.month - 1 + months;
    final year = start.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, start.day.clamp(1, lastDay));
  }
}
