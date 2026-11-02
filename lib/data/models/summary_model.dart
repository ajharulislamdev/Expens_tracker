enum SummaryPeriod { daily, weekly, monthly }

extension SummaryPeriodX on SummaryPeriod {
  String get label {
    switch (this) {
      case SummaryPeriod.daily:
        return 'Daily';
      case SummaryPeriod.weekly:
        return 'Weekly';
      case SummaryPeriod.monthly:
        return 'Monthly';
    }
  }
}

/// Plain (non-persisted) totals used by the dashboard and reports.
class SummaryModel {
  final double income;
  final double expense;
  final int count;

  const SummaryModel({
    this.income = 0,
    this.expense = 0,
    this.count = 0,
  });

  double get balance => income - expense;

  static const SummaryModel empty = SummaryModel();
}
