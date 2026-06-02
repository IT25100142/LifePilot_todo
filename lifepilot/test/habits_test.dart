import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Save and watch habits', () async {
    final habitsStream = db.watchHabits();

    var currentHabits = await habitsStream.first;
    expect(currentHabits.isEmpty, true);

    final habitId = await db.saveHabit(
      HabitsCompanion.insert(
        title: 'Morning Yoga',
        description: const Value('15 minutes of stretch'),
        categoryTag: const Value('Health & Fitness'),
      ),
    );

    currentHabits = await habitsStream.first;
    expect(currentHabits.length, 1);
    expect(currentHabits.first.id, habitId);
    expect(currentHabits.first.title, 'Morning Yoga');
    expect(currentHabits.first.description, '15 minutes of stretch');
    expect(currentHabits.first.categoryTag, 'Health & Fitness');
  });

  test('Toggle habit logs', () async {
    final habitId = await db.saveHabit(
      HabitsCompanion.insert(
        title: 'Meditation',
        categoryTag: const Value('Mind & Soul'),
      ),
    );

    final today = DateTime.now();

    // Toggle today's log to complete (true)
    await db.toggleHabitLog(habitId, today, true);

    var logs = await db.watchAllHabitLogs().first;
    expect(logs.length, 1);
    expect(logs.first.habitId, habitId);
    expect(logs.first.isCompleted, true);

    // Toggle today's log to incomplete (false)
    await db.toggleHabitLog(habitId, today, false);
    logs = await db.watchAllHabitLogs().first;
    expect(logs.isEmpty, true);
  });

  test('Habit delete cascades to logs', () async {
    final habitId = await db.saveHabit(
      HabitsCompanion.insert(
        title: 'Reading',
        categoryTag: const Value('Learning'),
      ),
    );

    final today = DateTime.now();
    await db.toggleHabitLog(habitId, today, true);

    var habits = await db.watchHabits().first;
    var logs = await db.watchAllHabitLogs().first;
    expect(habits.length, 1);
    expect(logs.length, 1);

    // Delete the habit
    await db.deleteHabit(habitId);

    habits = await db.watchHabits().first;
    logs = await db.watchAllHabitLogs().first;
    expect(habits.isEmpty, true);
    expect(logs.isEmpty, true); // Verified cascade delete works perfectly
  });
}
