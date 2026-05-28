import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_provider.dart';
import '../../core/services/notification_service.dart';
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

final toggleTaskCompletionProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return (Task task) async {
    final nextStatus = !task.isCompleted;

    // 1. Toggle completion on the current task
    await db.update(db.tasks).replace(
      task.copyWith(
        isCompleted: nextStatus,
        updatedAt: DateTime.now(),
      ),
    );

    // 2. Cancel original reminder if completing it
    if (nextStatus) {
      await notificationService.cancel(taskReminderId(task.id));
    }

    // 3. Auto-generate the next occurrence if completing a recurring task
    if (nextStatus && task.recurrencePattern != null && task.recurrencePattern != 'none') {
      final pattern = task.recurrencePattern!;
      final currentDue = task.dueDate ?? DateTime.now();
      final nextDue = calculateNextDueDate(currentDue, pattern);

      // Determine next reminder date preserving duration offset from due date
      DateTime? nextReminderAt;
      if (task.reminderAt != null && task.dueDate != null) {
        final offset = task.reminderAt!.difference(task.dueDate!);
        nextReminderAt = nextDue.add(offset);
      } else if (task.reminderAt != null) {
        nextReminderAt = calculateNextDueDate(task.reminderAt!, pattern);
      }

      final parentId = task.recurrenceParentId ?? task.id;

      final nextTask = TasksCompanion.insert(
        title: task.title,
        description: Value(task.description),
        dueDate: Value(nextDue),
        reminderAt: Value(nextReminderAt),
        priority: Value(task.priority),
        tags: Value(task.tags),
        isCompleted: const Value(false),
        recurrencePattern: Value(task.recurrencePattern),
        recurrenceParentId: Value(parentId),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      final nextTaskId = await db.saveTask(nextTask);

      // Schedule notification for the next task
      if (nextReminderAt != null && nextReminderAt.isAfter(DateTime.now())) {
        await notificationService.schedule(
          id: taskReminderId(nextTaskId),
          title: 'Task reminder',
          body: task.title,
          when: nextReminderAt,
        );
      }
    }
  };
});

DateTime calculateNextDueDate(DateTime current, String pattern) {
  switch (pattern) {
    case 'daily':
      return current.add(const Duration(days: 1));
    case 'weekly':
      return current.add(const Duration(days: 7));
    case 'monthly':
      var nextYear = current.year;
      var nextMonth = current.month + 1;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }
      var nextDay = current.day;
      final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      if (nextDay > daysInNextMonth) {
        nextDay = daysInNextMonth;
      }
      return DateTime(
        nextYear,
        nextMonth,
        nextDay,
        current.hour,
        current.minute,
        current.second,
        current.millisecond,
        current.microsecond,
      );
    default:
      return current;
  }
}
