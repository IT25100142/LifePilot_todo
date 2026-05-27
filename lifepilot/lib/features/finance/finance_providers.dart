import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    } else {
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
