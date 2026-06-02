import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../calendar/calendar_providers.dart';
import '../finance/finance_providers.dart';
import '../todo/todo_providers.dart';

class GlobalSearchResults {
  const GlobalSearchResults({
    required this.tasks,
    required this.events,
    required this.transactions,
  });

  final List<Task> tasks;
  final List<CalendarEvent> events;
  final List<FinanceEntry> transactions;

  bool get isEmpty => tasks.isEmpty && events.isEmpty && transactions.isEmpty;
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final globalSearchResultsProvider = Provider<AsyncValue<GlobalSearchResults>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  final tasksAsync = ref.watch(tasksProvider);
  final eventsAsync = ref.watch(eventsProvider);
  final financeAsync = ref.watch(financeEntriesProvider);

  if (query.isEmpty) {
    return const AsyncValue.data(
      GlobalSearchResults(tasks: [], events: [], transactions: []),
    );
  }

  return tasksAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (tasksList) {
      return eventsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
        data: (eventsList) {
          return financeAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
            data: (financeList) {
              final filteredTasks = tasksList.where((task) {
                return task.title.toLowerCase().contains(query) ||
                    task.description.toLowerCase().contains(query) ||
                    task.tags.toLowerCase().contains(query);
              }).toList();

              final filteredEvents = eventsList.where((event) {
                return event.title.toLowerCase().contains(query) ||
                    event.description.toLowerCase().contains(query);
              }).toList();

              final filteredFinance = financeList.where((entry) {
                return entry.title.toLowerCase().contains(query) ||
                    entry.category.toLowerCase().contains(query) ||
                    entry.note.toLowerCase().contains(query);
              }).toList();

              return AsyncValue.data(
                GlobalSearchResults(
                  tasks: filteredTasks,
                  events: filteredEvents,
                  transactions: filteredFinance,
                ),
              );
            },
          );
        },
      );
    },
  );
});
