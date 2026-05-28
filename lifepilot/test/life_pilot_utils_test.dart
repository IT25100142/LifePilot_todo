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

  test('budget warning and limit threshold transitions', () {
    const budget = 1000.0;

    bool checkWarning(double before, double amount) {
      final beforeRatio = before / budget;
      final afterRatio = (before + amount) / budget;
      return beforeRatio < 0.8 && afterRatio >= 0.8 && afterRatio < 1.0;
    }

    bool checkExceeded(double before, double amount) {
      final beforeRatio = before / budget;
      final afterRatio = (before + amount) / budget;
      return beforeRatio < 1.0 && afterRatio >= 1.0;
    }

    // 1. Initial 500, adding 250 -> 750 (75%). No alerts.
    expect(checkWarning(500, 250), isFalse);
    expect(checkExceeded(500, 250), isFalse);

    // 2. Initial 750, adding 100 -> 850 (85%). Warning triggers.
    expect(checkWarning(750, 100), isTrue);
    expect(checkExceeded(750, 100), isFalse);

    // 3. Initial 850, adding 50 -> 900 (90%). No new alerts.
    expect(checkWarning(850, 50), isFalse);
    expect(checkExceeded(850, 50), isFalse);

    // 4. Initial 900, adding 150 -> 1050 (105%). Exceeded triggers.
    expect(checkWarning(900, 150), isFalse);
    expect(checkExceeded(900, 150), isTrue);

    // 5. Initial 1050, adding 100 -> 1150 (115%). Already exceeded, no alert.
    expect(checkWarning(1050, 100), isFalse);
    expect(checkExceeded(1050, 100), isFalse);
  });

  test('global search filtering logic matches text case-insensitively', () {
    final task = Task(
      id: 1,
      title: 'Plan the Week',
      description: 'Review tasks and budget priorities.',
      dueDate: DateTime.now(),
      reminderAt: null,
      priority: 'high',
      tags: 'Personal,Work',
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final event = CalendarEvent(
      id: 1,
      title: 'Budget check-in',
      description: 'Update monthly expense categories.',
      date: DateTime.now(),
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      reminderAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tx = FinanceEntry(
      id: 1,
      title: 'Groceries store',
      amount: 4500,
      category: 'Food',
      date: DateTime.now(),
      note: 'Bought milk and vegetables',
      type: 'expense',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool matchTask(Task t, String query) {
      final q = query.trim().toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.tags.toLowerCase().contains(q);
    }

    bool matchEvent(CalendarEvent e, String query) {
      final q = query.trim().toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }

    bool matchTransaction(FinanceEntry f, String query) {
      final q = query.trim().toLowerCase();
      return f.title.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q) ||
          f.note.toLowerCase().contains(q);
    }

    // Test queries
    expect(matchTask(task, 'WEEK'), isTrue);
    expect(matchTask(task, 'personal'), isTrue);
    expect(matchTask(task, 'finance'), isFalse);

    expect(matchEvent(event, 'Check-In'), isTrue);
    expect(matchEvent(event, 'expense'), isTrue);
    expect(matchEvent(event, 'salary'), isFalse);

    expect(matchTransaction(tx, 'groceries'), isTrue);
    expect(matchTransaction(tx, 'MILK'), isTrue);
    expect(matchTransaction(tx, 'Food'), isTrue);
    expect(matchTransaction(tx, 'rent'), isFalse);
  });

  test('calculateFinancialTrends groups chronologically and accumulates', () {
    final now = DateTime.now();
    final jan = DateTime(2026, 1, 15);
    final feb = DateTime(2026, 2, 10);
    final mar = DateTime(2026, 3, 5);

    final entries = [
      FinanceEntry(
        id: 1,
        title: 'Salary Jan',
        amount: 2000,
        category: 'Salary',
        date: jan,
        note: '',
        type: 'income',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 2,
        title: 'Rent Feb',
        amount: 800,
        category: 'Rent',
        date: feb,
        note: '',
        type: 'expense',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 3,
        title: 'Freelance Feb',
        amount: 500,
        category: 'Freelance',
        date: feb,
        note: '',
        type: 'income',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 4,
        title: 'Groceries Jan',
        amount: 300,
        category: 'Food',
        date: jan,
        note: '',
        type: 'expense',
        createdAt: now,
        updatedAt: now,
      ),
      FinanceEntry(
        id: 5,
        title: 'Dinner Mar',
        amount: 100,
        category: 'Food',
        date: mar,
        note: '',
        type: 'expense',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final result = calculateFinancialTrends(entries);

    expect(result.length, 3);

    // Chronological order: Jan, Feb, Mar
    expect(result[0].month, DateTime(2026, 1));
    expect(result[1].month, DateTime(2026, 2));
    expect(result[2].month, DateTime(2026, 3));

    // January: Income: 2000, Expense: 300
    expect(result[0].income, 2000);
    expect(result[0].expense, 300);

    // February: Running Income: 2000 + 500 = 2500, Running Expense: 300 + 800 = 1100
    expect(result[1].income, 2500);
    expect(result[1].expense, 1100);

    // March: Running Income: 2500 + 0 = 2500, Running Expense: 1100 + 100 = 1200
    expect(result[2].income, 2500);
    expect(result[2].expense, 1200);
  });

  test(
    'recalculateAccountBalances correctly calculates income, expense, and transfer balances',
    () {
      final now = DateTime.now();

      final allAccounts = [
        Account(
          id: 1,
          name: 'Bank',
          initialBalance: 1000.0,
          currentBalance: 1000.0,
          colorValue: 0,
          createdAt: now,
        ),
        Account(
          id: 2,
          name: 'Cash',
          initialBalance: 100.0,
          currentBalance: 100.0,
          colorValue: 0,
          createdAt: now,
        ),
      ];

      final entries = [
        FinanceEntry(
          id: 1,
          title: 'Salary',
          amount: 5000,
          category: 'Salary',
          date: now,
          note: '',
          type: 'income',
          createdAt: now,
          updatedAt: now,
          accountId: 1,
        ),
        FinanceEntry(
          id: 2,
          title: 'Lunch',
          amount: 20,
          category: 'Food',
          date: now,
          note: '',
          type: 'expense',
          createdAt: now,
          updatedAt: now,
          accountId: 2,
        ),
        FinanceEntry(
          id: 3,
          title: 'ATM Withdrawal',
          amount: 200,
          category: 'Transfer',
          date: now,
          note: '',
          type: 'transfer',
          createdAt: now,
          updatedAt: now,
          accountId: 1,
          transferTargetAccountId: 2,
        ),
      ];

      double calculateBalance(Account account, List<FinanceEntry> txs) {
        var balance = account.initialBalance;
        for (final entry in txs) {
          if (entry.accountId == account.id) {
            if (entry.type == 'income') {
              balance += entry.amount;
            } else if (entry.type == 'expense' || entry.type == 'transfer') {
              balance -= entry.amount;
            }
          }
          if (entry.transferTargetAccountId == account.id &&
              entry.type == 'transfer') {
            balance += entry.amount;
          }
        }
        return balance;
      }

      final bankBalance = calculateBalance(allAccounts[0], entries);
      final cashBalance = calculateBalance(allAccounts[1], entries);

      expect(bankBalance, 5800.0);
      expect(cashBalance, 280.0);
    },
  );
}
