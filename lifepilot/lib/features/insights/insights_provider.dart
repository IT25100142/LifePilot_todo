import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/life_pilot_currency.dart';
import '../../core/services/exchange_rate_provider.dart';
import '../../data/database/app_database.dart';
import '../calendar/calendar_providers.dart';
import '../finance/finance_providers.dart';
import '../habits/habit_providers.dart';
import '../settings/settings_providers.dart';

class SystemInsights {
  const SystemInsights({
    required this.runwayDays,
    required this.behavioralInsight,
  });

  final int runwayDays;
  final String behavioralInsight;
}

class InsightsPayload {
  const InsightsPayload({
    required this.accounts,
    required this.financeEntries,
    required this.habitLogs,
    required this.habits,
    required this.events,
    required this.activeCurrency,
    required this.exchangeRates,
  });

  final List<Account> accounts;
  final List<FinanceEntry> financeEntries;
  final List<HabitLog> habitLogs;
  final List<Habit> habits;
  final List<CalendarEvent> events;
  final String activeCurrency;
  final Map<LifePilotCurrency, double> exchangeRates;
}

SystemInsights _computeInsights(InsightsPayload payload) {
  final now = DateTime.now();
  final targetCurrency = currencyFromCode(payload.activeCurrency);

  // --- Fiscal Runway ---
  double totalLiquid = 0.0;
  for (final account in payload.accounts) {
    // Assuming account balances are stored in USD (default) if not explicitly set.
    final rateTo = payload.exchangeRates[targetCurrency] ?? 1.0;
    final rateFromUsd = payload.exchangeRates[LifePilotCurrency.usd] ?? 1.0;

    final converted = rateFromUsd > 0
        ? account.currentBalance * (rateTo / rateFromUsd)
        : account.currentBalance;
    totalLiquid += converted;
  }

  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  double totalExpenses30Days = 0.0;
  for (final entry in payload.financeEntries) {
    if (entry.type == 'expense' && entry.date.isAfter(thirtyDaysAgo)) {
      final entryCurrency = currencyFromCode(
        entry.currency.isEmpty ? AppConstants.defaultCurrency : entry.currency,
      );
      final rateFrom = payload.exchangeRates[entryCurrency] ?? 1.0;
      final rateTo = payload.exchangeRates[targetCurrency] ?? 1.0;
      final convertedAmount = rateFrom > 0
          ? entry.amount * (rateTo / rateFrom)
          : entry.amount;
      totalExpenses30Days += convertedAmount;
    }
  }

  final avgDailyExpense = totalExpenses30Days / 30.0;
  int runwayDays = 0;
  if (avgDailyExpense > 0) {
    runwayDays = (totalLiquid / avgDailyExpense).floor();
  }

  // --- Behavioral Co-efficiency ---
  final habitLogsByDate = <DateTime, List<HabitLog>>{};
  for (final log in payload.habitLogs) {
    final date = DateTime(log.date.year, log.date.month, log.date.day);
    habitLogsByDate.putIfAbsent(date, () => []).add(log);
  }

  final focusMinutesByDate = <DateTime, int>{};
  for (final event in payload.events) {
    if (event.title.startsWith('Focus Session:')) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      final minutes = event.endTime.difference(event.startTime).inMinutes;
      focusMinutesByDate.update(
        date,
        (v) => v + minutes,
        ifAbsent: () => minutes,
      );
    }
  }

  final lowHabitDays = <DateTime>{};
  final normalDays = <DateTime>{};
  final totalHabits = payload.habits.length;

  if (totalHabits > 0) {
    for (final entry in habitLogsByDate.entries) {
      final logs = entry.value;
      if (logs.isEmpty) continue;
      int completedCount = logs.where((l) => l.isCompleted).length;
      double completionRate = completedCount / totalHabits;
      if (completionRate < 0.5) {
        lowHabitDays.add(entry.key);
      } else {
        normalDays.add(entry.key);
      }
    }
  }

  double avgFocusLow = 0;
  double avgFocusNormal = 0;

  if (lowHabitDays.isNotEmpty) {
    int totalFocusLow = 0;
    for (final day in lowHabitDays) {
      totalFocusLow += focusMinutesByDate[day] ?? 0;
    }
    avgFocusLow = totalFocusLow / lowHabitDays.length;
  }

  if (normalDays.isNotEmpty) {
    int totalFocusNormal = 0;
    for (final day in normalDays) {
      totalFocusNormal += focusMinutesByDate[day] ?? 0;
    }
    avgFocusNormal = totalFocusNormal / normalDays.length;
  }

  String behavioralInsight = 'Optimal behavioral patterns detected.';

  if (normalDays.isNotEmpty && lowHabitDays.isNotEmpty && avgFocusNormal > 0) {
    if (avgFocusLow < avgFocusNormal * 0.8) {
      // Find outlier habit
      final missedCounts = <int, int>{};
      for (final day in lowHabitDays) {
        final logsOnDay = habitLogsByDate[day] ?? [];
        for (final habit in payload.habits) {
          final log = logsOnDay.where((l) => l.habitId == habit.id).firstOrNull;
          if (log == null || !log.isCompleted) {
            missedCounts.update(habit.id, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      }

      if (missedCounts.isNotEmpty) {
        final outlierEntry = missedCounts.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        final outlierHabit = payload.habits.firstWhere(
          (h) => h.id == outlierEntry.key,
          orElse: () => payload.habits.first,
        );
        final dropPercentage = ((1 - (avgFocusLow / avgFocusNormal)) * 100)
            .round();

        behavioralInsight =
            "Insight: Focus session duration drops by an average of $dropPercentage% on days when '${outlierHabit.title}' is missed.";
      }
    }
  }

  return SystemInsights(
    runwayDays: runwayDays > 0 ? runwayDays : 0,
    behavioralInsight: behavioralInsight,
  );
}

final systemInsightsProvider = FutureProvider<SystemInsights>((ref) async {
  final accountsAsync = ref.watch(accountsStreamProvider);
  final entriesAsync = ref.watch(financeEntriesProvider);
  final habitLogsAsync = ref.watch(habitLogsProvider);
  final habitsAsync = ref.watch(habitsProvider);
  final eventsAsync = ref.watch(eventsProvider);

  if (accountsAsync.isLoading ||
      entriesAsync.isLoading ||
      habitLogsAsync.isLoading ||
      habitsAsync.isLoading ||
      eventsAsync.isLoading) {
    throw Exception('Loading insights...');
  }

  final payload = InsightsPayload(
    accounts: accountsAsync.valueOrNull ?? [],
    financeEntries: entriesAsync.valueOrNull ?? [],
    habitLogs: habitLogsAsync.valueOrNull ?? [],
    habits: habitsAsync.valueOrNull ?? [],
    events: eventsAsync.valueOrNull ?? [],
    activeCurrency: ref.watch(activeCurrencyCodeProvider),
    exchangeRates: ref.watch(exchangeRateProvider).rates,
  );

  return await Isolate.run(() => _computeInsights(payload));
});
