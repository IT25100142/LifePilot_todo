import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../todo/todo_providers.dart';

final selectedCalendarDayProvider = StateProvider<DateTime>((ref) {
  return startOfDay(DateTime.now());
});

final visibleCalendarMonthProvider = StateProvider<DateTime>((ref) {
  return startOfMonth(DateTime.now());
});

final eventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchEvents();
});

final selectedDayEventsProvider = Provider<AsyncValue<List<CalendarEvent>>>((
  ref,
) {
  final selected = ref.watch(selectedCalendarDayProvider);
  return ref.watch(eventsProvider).whenData((items) {
    return items.where((event) => isSameDate(event.date, selected)).toList();
  });
});

final selectedDayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final selected = ref.watch(selectedCalendarDayProvider);
  return ref.watch(tasksProvider).whenData((items) {
    return items.where((task) {
      final due = task.dueDate;
      return due != null && isSameDate(due, selected);
    }).toList();
  });
});
