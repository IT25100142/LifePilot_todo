import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

enum FinanceTypeFilter { all, income, expense }

class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.byCategory,
  });

  final double income;
  final double expenses;
  final double balance;
  final Map<String, double> byCategory;
}

final selectedFinanceMonthProvider = StateProvider<DateTime>((ref) {
  return startOfMonth(DateTime.now());
});

final selectedFinanceCategoryProvider = StateProvider<String?>((ref) => null);
final selectedFinanceTypeProvider = StateProvider<FinanceTypeFilter>(
  (ref) => FinanceTypeFilter.all,
);

final financeEntriesProvider = StreamProvider<List<FinanceEntry>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchFinanceEntries();
});

final filteredFinanceEntriesProvider = Provider<AsyncValue<List<FinanceEntry>>>(
  (ref) {
    final selectedMonth = ref.watch(selectedFinanceMonthProvider);
    final category = ref.watch(selectedFinanceCategoryProvider);
    final type = ref.watch(selectedFinanceTypeProvider);

    return ref.watch(financeEntriesProvider).whenData((items) {
      return items.where((entry) {
        final inMonth =
            entry.date.year == selectedMonth.year &&
            entry.date.month == selectedMonth.month;
        final matchesCategory = category == null || entry.category == category;
        final matchesType = switch (type) {
          FinanceTypeFilter.all => true,
          FinanceTypeFilter.income => entry.type == 'income',
          FinanceTypeFilter.expense => entry.type == 'expense',
        };
        return inMonth && matchesCategory && matchesType;
      }).toList();
    });
  },
);

final financeSummaryProvider = Provider<AsyncValue<FinanceSummary>>((ref) {
  return ref
      .watch(filteredFinanceEntriesProvider)
      .whenData(buildFinanceSummary);
});

FinanceSummary buildFinanceSummary(List<FinanceEntry> entries) {
  var income = 0.0;
  var expenses = 0.0;
  final byCategory = <String, double>{};

  for (final entry in entries) {
    if (entry.type == 'income') {
      income += entry.amount;
    } else if (entry.type == 'expense') {
      expenses += entry.amount;
      byCategory.update(
        entry.category,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
  }

  return FinanceSummary(
    income: income,
    expenses: expenses,
    balance: income - expenses,
    byCategory: byCategory,
  );
}

class CategoryBudgetStatus {
  CategoryBudgetStatus({
    required this.category,
    required this.spent,
    required this.budget,
  });

  final Category category;
  final double spent;
  final double budget;

  double get ratio => budget > 0 ? spent / budget : 0.0;
  bool get hasBudget => budget > 0;
  bool get isNearLimit => hasBudget && ratio >= 0.8 && ratio < 1.0;
  bool get isOverLimit => hasBudget && ratio >= 1.0;
}

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchCategories();
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAccounts();
});

final categoryBudgetStatusProvider =
    Provider<AsyncValue<List<CategoryBudgetStatus>>>((ref) {
      final categoriesAsync = ref.watch(categoriesStreamProvider);
      final selectedMonth = ref.watch(selectedFinanceMonthProvider);
      final financeEntriesAsync = ref.watch(financeEntriesProvider);

      return categoriesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
        data: (categories) {
          return financeEntriesAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
            data: (entries) {
              final monthlyExpenses = <String, double>{};
              for (final entry in entries) {
                final inMonth =
                    entry.date.year == selectedMonth.year &&
                    entry.date.month == selectedMonth.month;
                if (inMonth && entry.type == 'expense') {
                  monthlyExpenses.update(
                    entry.category,
                    (val) => val + entry.amount,
                    ifAbsent: () => entry.amount,
                  );
                }
              }

              final statusList = categories.map((cat) {
                final spent = monthlyExpenses[cat.name] ?? 0.0;
                final budget = cat.monthlyBudget ?? 0.0;
                return CategoryBudgetStatus(
                  category: cat,
                  spent: spent,
                  budget: budget,
                );
              }).toList();

              return AsyncValue.data(statusList);
            },
          );
        },
      );
    });

final saveFinanceTransactionProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return (FinanceEntriesCompanion transactionCompanion) async {
    final entryType = transactionCompanion.type.value;
    final entryCategory = transactionCompanion.category.value;
    final entryAmount = transactionCompanion.amount.value;
    final entryDate = transactionCompanion.date.value;

    if (entryType == 'expense') {
      final categoriesList = await db.select(db.categories).get();
      final categoryMatch = categoriesList.firstWhere(
        (c) => c.name == entryCategory,
        orElse: () => Category(
          id: 0,
          name: entryCategory,
          type: 'finance',
          colorValue: 0,
          iconName: '',
          monthlyBudget: null,
        ),
      );

      final budget = categoryMatch.monthlyBudget ?? 0.0;
      if (budget > 0) {
        final allEntries = await db.select(db.financeEntries).get();
        final currentMonth = startOfMonth(entryDate);

        var spentBefore = 0.0;
        final existingId = transactionCompanion.id.present
            ? transactionCompanion.id.value
            : null;

        for (final entry in allEntries) {
          final inMonth =
              entry.date.year == currentMonth.year &&
              entry.date.month == currentMonth.month;
          if (inMonth &&
              entry.type == 'expense' &&
              entry.category == entryCategory) {
            if (existingId != null && entry.id == existingId) {
              continue;
            }
            spentBefore += entry.amount;
          }
        }

        final spentAfter = spentBefore + entryAmount;
        final newId = await db.saveFinanceEntryWithBalance(
          transactionCompanion,
        );

        final beforeRatio = spentBefore / budget;
        final afterRatio = spentAfter / budget;

        if (beforeRatio < 0.8 && afterRatio >= 0.8 && afterRatio < 1.0) {
          await notificationService.schedule(
            id: 300000 + (existingId ?? newId),
            title: 'Budget Alert (80%+)',
            body:
                'You have spent ${spentAfter.toStringAsFixed(2)} of your ${budget.toStringAsFixed(2)} budget for $entryCategory.',
            when: DateTime.now().add(const Duration(seconds: 1)),
          );
        } else if (beforeRatio < 1.0 && afterRatio >= 1.0) {
          await notificationService.schedule(
            id: 400000 + (existingId ?? newId),
            title: 'Budget Exceeded (100%+)',
            body:
                'Alert! You spent ${spentAfter.toStringAsFixed(2)} exceeding your ${budget.toStringAsFixed(2)} budget for $entryCategory!',
            when: DateTime.now().add(const Duration(seconds: 1)),
          );
        }

        return newId;
      }
    }

    return db.saveFinanceEntryWithBalance(transactionCompanion);
  };
});

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

final financialTrendProvider = Provider<AsyncValue<List<MonthlyTrendPoint>>>((
  ref,
) {
  return ref.watch(financeEntriesProvider).whenData(calculateFinancialTrends);
});

List<MonthlyTrendPoint> calculateFinancialTrends(List<FinanceEntry> entries) {
  if (entries.isEmpty) return const [];

  // Group entries by calendar month
  final grouped = <DateTime, List<FinanceEntry>>{};
  for (final entry in entries) {
    final monthKey = DateTime(entry.date.year, entry.date.month);
    grouped.putIfAbsent(monthKey, () => []).add(entry);
  }

  // Sort months chronologically
  final sortedMonths = grouped.keys.toList()..sort();

  // Compute running totals
  final trendPoints = <MonthlyTrendPoint>[];
  var runningIncome = 0.0;
  var runningExpense = 0.0;

  for (final month in sortedMonths) {
    final monthEntries = grouped[month]!;
    var monthIncome = 0.0;
    var monthExpense = 0.0;

    for (final entry in monthEntries) {
      if (entry.type == 'income') {
        monthIncome += entry.amount;
      } else if (entry.type == 'expense') {
        monthExpense += entry.amount;
      }
    }

    runningIncome += monthIncome;
    runningExpense += monthExpense;

    trendPoints.add(
      MonthlyTrendPoint(
        month: month,
        income: runningIncome,
        expense: runningExpense,
      ),
    );
  }

  return trendPoints;
}
