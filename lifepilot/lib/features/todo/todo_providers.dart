import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

enum TaskFilter { all, today, upcoming, completed, overdue }

enum TaskSort { dueDate, priority, createdDate }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final taskSortProvider = StateProvider<TaskSort>((ref) => TaskSort.dueDate);
final taskSearchProvider = StateProvider<String>((ref) => '');

final tasksProvider = StreamProvider<List<Task>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchTasks();
});

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  final sort = ref.watch(taskSortProvider);
  final search = ref.watch(taskSearchProvider).trim().toLowerCase();

  return tasks.whenData((items) {
    final now = DateTime.now();
    final today = startOfDay(now);
    var result = items.where((task) {
      final due = task.dueDate;
      final matchesSearch =
          search.isEmpty ||
          task.title.toLowerCase().contains(search) ||
          task.description.toLowerCase().contains(search) ||
          task.tags.toLowerCase().contains(search);
      if (!matchesSearch) return false;

      return switch (filter) {
        TaskFilter.all => true,
        TaskFilter.today => due != null && isSameDate(due, today),
        TaskFilter.upcoming =>
          due != null && due.isAfter(endOfDay(today)) && !task.isCompleted,
        TaskFilter.completed => task.isCompleted,
        TaskFilter.overdue =>
          due != null && due.isBefore(now) && !task.isCompleted,
      };
    }).toList();

    result.sort((a, b) {
      return switch (sort) {
        TaskSort.dueDate => (a.dueDate ?? DateTime(9999)).compareTo(
          b.dueDate ?? DateTime(9999),
        ),
        TaskSort.createdDate => b.createdAt.compareTo(a.createdAt),
        TaskSort.priority => _priorityWeight(
          b.priority,
        ).compareTo(_priorityWeight(a.priority)),
      };
    });
    return result;
  });
});

int _priorityWeight(String priority) {
  return switch (priority) {
    'high' => 3,
    'medium' => 2,
    _ => 1,
  };
}
