import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

enum TaskPriority { low, medium, high }

enum TransactionType { income, expense }

enum CategoryType { task, finance, both }

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 140)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get recurrencePattern => text().nullable()();
  IntColumn get recurrenceParentId => integer().nullable()();
}

class CalendarEvents extends Table {
  @override
  String get tableName => 'events';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 140)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class FinanceEntries extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 140)();
  RealColumn get amount => real()();
  TextColumn get category => text().withDefault(const Constant('Other'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text().withDefault(const Constant('both'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF286C63))();
  TextColumn get iconName => text().withDefault(const Constant('label'))();
}

class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get currency =>
      text().withDefault(const Constant(AppConstants.defaultCurrency))();
  BoolColumn get demoSeeded => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [Tasks, CalendarEvents, FinanceEntries, Categories, AppSettingsTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'lifepilot',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.recurrencePattern);
            await m.addColumn(tasks, tasks.recurrenceParentId);
          }
        },
      );

  Future<void> ensureSeedData() async {
    final settings = await _settingsRow();
    if (settings.demoSeeded) return;

    await transaction(() async {
      await _seedCategories();
      await _seedTasks();
      await _seedEvents();
      await _seedFinanceEntries();
      await update(
        appSettingsTable,
      ).replace(settings.copyWith(demoSeeded: true));
    });
  }

  Stream<AppSettingsTableData> watchSettings() async* {
    await _ensureSettingsRow();
    yield* (select(appSettingsTable)..limit(1)).watchSingle();
  }

  Future<AppSettingsTableData> readSettings() => _settingsRow();

  Future<void> updateThemeMode(String mode) async {
    final settings = await _settingsRow();
    await update(appSettingsTable).replace(settings.copyWith(themeMode: mode));
  }

  Future<void> updateCurrency(String currency) async {
    final settings = await _settingsRow();
    await update(
      appSettingsTable,
    ).replace(settings.copyWith(currency: currency));
  }

  Stream<List<Task>> watchTasks() {
    return (select(
      tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<int> saveTask(TasksCompanion entry) {
    return into(tasks).insertOnConflictUpdate(entry);
  }

  Future<void> deleteTask(int id) async {
    await (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleTask(Task task) {
    return update(tasks).replace(
      task.copyWith(isCompleted: !task.isCompleted, updatedAt: DateTime.now()),
    );
  }

  Stream<List<CalendarEvent>> watchEvents() {
    return (select(
      calendarEvents,
    )..orderBy([(e) => OrderingTerm.asc(e.startTime)])).watch();
  }

  Future<int> saveEvent(CalendarEventsCompanion entry) {
    return into(calendarEvents).insertOnConflictUpdate(entry);
  }

  Future<void> deleteEvent(int id) async {
    await (delete(calendarEvents)..where((e) => e.id.equals(id))).go();
  }

  Stream<List<FinanceEntry>> watchFinanceEntries() {
    return (select(
      financeEntries,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  Future<int> saveFinanceEntry(FinanceEntriesCompanion entry) {
    return into(financeEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteFinanceEntry(int id) async {
    await (delete(financeEntries)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Category>> watchCategories() {
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(tasks).go();
      await delete(calendarEvents).go();
      await delete(financeEntries).go();
      await delete(categories).go();
      await delete(appSettingsTable).go();
      await into(appSettingsTable).insert(
        const AppSettingsTableCompanion(
          currency: Value(AppConstants.defaultCurrency),
          themeMode: Value('system'),
          demoSeeded: Value(true),
        ),
      );
    });
  }

  Future<void> importJson(Map<String, dynamic> payload) async {
    await transaction(() async {
      await clearAllData();
      for (final item in (payload['tasks'] as List<dynamic>? ?? const [])) {
        final json = item as Map<String, dynamic>;
        await into(tasks).insert(
          TasksCompanion.insert(
            title: json['title'] as String? ?? 'Imported task',
            description: Value(json['description'] as String? ?? ''),
            dueDate: Value(_date(json['dueDate'])),
            reminderAt: Value(_date(json['reminderAt'])),
            priority: Value(json['priority'] as String? ?? 'medium'),
            tags: Value(json['tags'] as String? ?? ''),
            isCompleted: Value(json['isCompleted'] as bool? ?? false),
            createdAt: Value(_date(json['createdAt']) ?? DateTime.now()),
            updatedAt: Value(_date(json['updatedAt']) ?? DateTime.now()),
            recurrencePattern: Value(json['recurrencePattern'] as String?),
            recurrenceParentId: Value(json['recurrenceParentId'] as int?),
          ),
        );
      }
      for (final item in (payload['events'] as List<dynamic>? ?? const [])) {
        final json = item as Map<String, dynamic>;
        final start = _date(json['startTime']) ?? DateTime.now();
        await into(calendarEvents).insert(
          CalendarEventsCompanion.insert(
            title: json['title'] as String? ?? 'Imported event',
            description: Value(json['description'] as String? ?? ''),
            date: _date(json['date']) ?? start,
            startTime: start,
            endTime:
                _date(json['endTime']) ?? start.add(const Duration(hours: 1)),
            reminderAt: Value(_date(json['reminderAt'])),
            createdAt: Value(_date(json['createdAt']) ?? DateTime.now()),
            updatedAt: Value(_date(json['updatedAt']) ?? DateTime.now()),
          ),
        );
      }
      for (final item
          in (payload['transactions'] as List<dynamic>? ?? const [])) {
        final json = item as Map<String, dynamic>;
        await into(financeEntries).insert(
          FinanceEntriesCompanion.insert(
            title: json['title'] as String? ?? 'Imported transaction',
            amount: (json['amount'] as num?)?.toDouble() ?? 0,
            category: Value(json['category'] as String? ?? 'Other'),
            date: _date(json['date']) ?? DateTime.now(),
            note: Value(json['note'] as String? ?? ''),
            type: Value(json['type'] as String? ?? 'expense'),
            createdAt: Value(_date(json['createdAt']) ?? DateTime.now()),
            updatedAt: Value(_date(json['updatedAt']) ?? DateTime.now()),
          ),
        );
      }
      await _seedCategories();
      final settings = await _settingsRow();
      await update(appSettingsTable).replace(
        settings.copyWith(
          currency: payload['currency'] as String? ?? settings.currency,
          demoSeeded: true,
        ),
      );
    });
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<AppSettingsTableData> _settingsRow() async {
    await _ensureSettingsRow();
    return (select(appSettingsTable)..limit(1)).getSingle();
  }

  Future<void> _ensureSettingsRow() async {
    final rows = await select(appSettingsTable).get();
    if (rows.isEmpty) {
      await into(appSettingsTable).insert(const AppSettingsTableCompanion());
    } else if (rows.length > 1) {
      final keep = rows.first;
      await delete(appSettingsTable).go();
      await into(appSettingsTable).insert(
        AppSettingsTableCompanion.insert(
          themeMode: Value(keep.themeMode),
          currency: Value(keep.currency),
          demoSeeded: Value(keep.demoSeeded),
        ),
      );
    }
  }

  Future<void> _seedCategories() async {
    final existing = await select(categories).get();
    if (existing.isNotEmpty) return;

    final colors = [
      0xFF286C63,
      0xFF4B66D3,
      0xFFC77D2B,
      0xFF8A5CF6,
      0xFFE0516F,
      0xFF2E8B57,
      0xFF607D8B,
      0xFF1E88E5,
      0xFF757575,
    ];
    for (var i = 0; i < AppConstants.financeCategories.length; i++) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: AppConstants.financeCategories[i],
          type: const Value('finance'),
          colorValue: Value(colors[i % colors.length]),
          iconName: const Value('category'),
        ),
      );
    }
    for (var i = 0; i < AppConstants.taskCategories.length; i++) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: AppConstants.taskCategories[i],
          type: const Value('task'),
          colorValue: Value(colors[(i + 2) % colors.length]),
          iconName: const Value('tag'),
        ),
      );
    }
  }

  Future<void> _seedTasks() async {
    if ((await select(tasks).get()).isNotEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await batch((batch) {
      batch.insertAll(tasks, [
        TasksCompanion.insert(
          title: 'Plan the week',
          description: const Value(
            'Review tasks, events, and budget priorities.',
          ),
          dueDate: Value(today.add(const Duration(hours: 17))),
          reminderAt: Value(today.add(const Duration(hours: 16))),
          priority: const Value('high'),
          tags: const Value('Personal,Work'),
        ),
        TasksCompanion.insert(
          title: 'Pay utility bill',
          description: const Value('Check balance and record the payment.'),
          dueDate: Value(today.add(const Duration(days: 1, hours: 10))),
          priority: const Value('medium'),
          tags: const Value('Finance'),
        ),
        TasksCompanion.insert(
          title: 'Read 20 pages',
          dueDate: Value(today.add(const Duration(days: 3, hours: 20))),
          priority: const Value('low'),
          tags: const Value('Study'),
        ),
      ]);
    });
  }

  Future<void> _seedEvents() async {
    if ((await select(calendarEvents).get()).isNotEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await batch((batch) {
      batch.insertAll(calendarEvents, [
        CalendarEventsCompanion.insert(
          title: 'Morning review',
          description: const Value('Check dashboard and priorities.'),
          date: today,
          startTime: today.add(const Duration(hours: 9)),
          endTime: today.add(const Duration(hours: 9, minutes: 30)),
          reminderAt: Value(today.add(const Duration(hours: 8, minutes: 45))),
        ),
        CalendarEventsCompanion.insert(
          title: 'Budget check-in',
          description: const Value('Update monthly expense categories.'),
          date: today.add(const Duration(days: 2)),
          startTime: today.add(const Duration(days: 2, hours: 18)),
          endTime: today.add(const Duration(days: 2, hours: 19)),
        ),
      ]);
    });
  }

  Future<void> _seedFinanceEntries() async {
    if ((await select(financeEntries).get()).isNotEmpty) return;

    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(financeEntries, [
        FinanceEntriesCompanion.insert(
          title: 'Monthly salary',
          amount: 185000,
          category: const Value('Salary'),
          date: DateTime(now.year, now.month, 1),
          type: const Value('income'),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Groceries',
          amount: 12600,
          category: const Value('Food'),
          date: now.subtract(const Duration(days: 2)),
          type: const Value('expense'),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Internet bill',
          amount: 5900,
          category: const Value('Bills'),
          date: now.subtract(const Duration(days: 4)),
          type: const Value('expense'),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Train pass',
          amount: 3200,
          category: const Value('Transport'),
          date: now.subtract(const Duration(days: 7)),
          type: const Value('expense'),
        ),
      ]);
    });
  }
}
