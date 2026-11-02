import 'package:expense_tracker/core/services/daily_expense_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyExpenseReminderService.nextReminderDateTime', () {
    test('returns today when the reminder time is still upcoming', () {
      final next = DailyExpenseReminderService.nextReminderDateTime(
        DateTime(2026, 11, 3, 18, 30),
        hour: 21,
        minute: 0,
      );

      expect(next, DateTime(2026, 11, 3, 21));
    });

    test('returns tomorrow when the reminder time has passed', () {
      final next = DailyExpenseReminderService.nextReminderDateTime(
        DateTime(2026, 11, 3, 21, 0, 1),
        hour: 21,
        minute: 0,
      );

      expect(next, DateTime(2026, 11, 4, 21));
    });
  });
}
