import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/services/notification_service.dart';
import 'package:lifepilot/core/utils/date_helpers.dart';
import 'package:lifepilot/data/database/app_database.dart';
import 'package:lifepilot/features/finance/finance_providers.dart';
import 'package:lifepilot/features/todo/todo_providers.dart';

void main() {
  test('date helpers compare calendar days only', () {
    expect(
      isSameDate(DateTime(2026, 5, 27, 8), DateTime(2026, 5, 27, 23, 59)),
      isTrue,
    );
    expect(isSameDate(DateTime(2026, 5, 27), DateTime(2026, 5, 28)), isFalse);
  });

  test('finance summary separates income, expenses, and categories', () {
    final now = DateTime(2026, 5, 27);
    final summary = buildFinanceSummary([
      FinanceEntry(
        id: 1,
        title: 'Salary',
        amount: 1000,
        category: 'Salary',
        date: now,
        note: '',
        type: 'income',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 2,
        title: 'Lunch',
        amount: 250,
        category: 'Food',
        date: now,
        note: '',
        type: 'expense',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 3,
        title: 'Bus',
        amount: 100,
        category: 'Transport',
        date: now,
        note: '',
        type: 'expense',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(summary.income, 1000);
    expect(summary.expenses, 350);
    expect(summary.balance, 650);
    expect(summary.byCategory['Food'], 250);
    expect(summary.byCategory['Transport'], 100);
  });

  test('notification ids stay in separate ranges', () {
    expect(taskReminderId(7), 100007);
    expect(eventReminderId(7), 200007);
  });

  test('recurrence date calculations daily, weekly, monthly', () {
    final start = DateTime(2026, 5, 27, 9, 30);

    // Daily
    final nextDaily = calculateNextDueDate(start, 'daily');
    expect(nextDaily, DateTime(2026, 5, 28, 9, 30));

    // Weekly
    final nextWeekly = calculateNextDueDate(start, 'weekly');
    expect(nextWeekly, DateTime(2026, 6, 3, 9, 30));

    // Monthly
    final nextMonthly = calculateNextDueDate(start, 'monthly');
    expect(nextMonthly, DateTime(2026, 6, 27, 9, 30));

    // Monthly (Month-end boundary: Jan 31 -> Feb 28 in non-leap year 2026)
    final jan31 = DateTime(2026, 1, 31, 10, 0);
    final febNext = calculateNextDueDate(jan31, 'monthly');
    expect(febNext, DateTime(2026, 2, 28, 10, 0));

    // Monthly (Leap year boundary: Feb 29 -> Mar 29 in leap year 2024)
    final leapFeb29 = DateTime(2024, 2, 29, 12, 0);
    final marNext = calculateNextDueDate(leapFeb29, 'monthly');
    expect(marNext, DateTime(2024, 3, 29, 12, 0));
  });
}
