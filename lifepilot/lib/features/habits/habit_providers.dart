import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchHabits();
});

final habitLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAllHabitLogs();
});

class HabitActions {
  HabitActions(this._db);
  final AppDatabase _db;

  Future<int> addHabit({
    required String title,
    required String description,
    required String categoryTag,
  }) {
    return _db.saveHabit(
      HabitsCompanion.insert(
        title: title,
        description: Value(description),
        categoryTag: Value(categoryTag),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteHabit(int id) {
    return _db.deleteHabit(id);
  }

  Future<void> toggleHabitLog(int habitId, DateTime date, bool isCompleted) {
    return _db.toggleHabitLog(habitId, date, isCompleted);
  }
}

final habitActionsProvider = Provider<HabitActions>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HabitActions(db);
});
