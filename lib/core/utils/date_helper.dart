import '../../data/models/summary_model.dart';

class DateHelper {
  DateHelper._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// Week starts on Monday.
  static DateTime startOfWeek(DateTime d) =>
      startOfDay(d.subtract(Duration(days: d.weekday - 1)));

  static DateTime endOfWeek(DateTime d) =>
      endOfDay(startOfWeek(d).add(const Duration(days: 6)));

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime endOfMonth(DateTime d) =>
      endOfDay(DateTime(d.year, d.month + 1, 0));

  static DateTime startOf(SummaryPeriod p, [DateTime? ref]) {
    final d = ref ?? DateTime.now();
    switch (p) {
      case SummaryPeriod.daily:
        return startOfDay(d);
      case SummaryPeriod.weekly:
        return startOfWeek(d);
      case SummaryPeriod.monthly:
        return startOfMonth(d);
    }
  }

  static DateTime endOf(SummaryPeriod p, [DateTime? ref]) {
    final d = ref ?? DateTime.now();
    switch (p) {
      case SummaryPeriod.daily:
        return endOfDay(d);
      case SummaryPeriod.weekly:
        return endOfWeek(d);
      case SummaryPeriod.monthly:
        return endOfMonth(d);
    }
  }

  static bool isInRange(DateTime d, DateTime from, DateTime to) =>
      !d.isBefore(from) && !d.isAfter(to);
}
