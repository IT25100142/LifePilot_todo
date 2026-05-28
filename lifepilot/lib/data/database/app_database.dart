import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/backup_payload_v2.dart';
import '../../core/services/encryption_service.dart';

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
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  IntColumn get transferTargetAccountId => integer().nullable().references(Accounts, #id)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF286C63))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text().withDefault(const Constant('both'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF286C63))();
  TextColumn get iconName => text().withDefault(const Constant('label'))();
  RealColumn get monthlyBudget => real().nullable()();
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
  tables: [
    Tasks,
    CalendarEvents,
    FinanceEntries,
    Categories,
    AppSettingsTable,
    Accounts
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final encryptionKey = await EncryptionService.getOrGenerateKey();
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'lifepilot.sqlite'));

      return driftDatabase(
        name: 'lifepilot',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.dart.js'),
        ),
        native: DriftNativeOptions(
          setup: (rawDb) {
            rawDb.execute("PRAGMA key = '$encryptionKey';");
            try {
              // Verify encryption key succeeds on decrypting SQLite pages
              rawDb.select('SELECT name FROM sqlite_schema LIMIT 1;');
            } catch (e) {
              // Delete corrupted/mismatched DB file so app doesn't crash permanently
              try {
                if (file.existsSync()) {
                  file.deleteSync();
                }
              } catch (_) {}
              throw Exception('Database decryption failed. Local database has been reset.');
            }
          },
        ),
      );
    });
  }

  /// Rotates the database encryption key.
  Future<void> rotateEncryptionKey(String newKey) async {
    await customStatement("PRAGMA rekey = '$newKey';");
    await EncryptionService.rotateKey(newKey);
  }

  @override
  int get schemaVersion => 4;

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
          if (from < 3) {
            await m.addColumn(categories, categories.monthlyBudget);
          }
          if (from < 4) {
            await m.createTable(accounts);
            await m.addColumn(financeEntries, financeEntries.accountId);
            await m.addColumn(financeEntries,
                financeEntries.transferTargetAccountId);

            // Insert a default Primary Account
            final nowStr = DateTime.now().toIso8601String();
            final defaultAccountId = await customInsert(
                "INSERT INTO accounts (name, initial_balance, current_balance, color_value, created_at) "
                "VALUES ('Primary Account', 0.0, 0.0, 4280806499, '$nowStr');");
            // Set all existing transactions to point to this Primary Account
            await customUpdate(
                "UPDATE transactions SET account_id = $defaultAccountId WHERE account_id IS NULL;");
          }
        },
      );

  Future<void> ensureSeedData() async {
    final settings = await _settingsRow();
    if (settings.demoSeeded) return;

    await transaction(() async {
      await _seedCategories();
      await _seedAccounts();
      await _seedTasks();
      await _seedEvents();
      await _seedFinanceEntries();
      await recalculateAccountBalances();
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

  Future<int> saveCategory(CategoriesCompanion entry) {
    return into(categories).insertOnConflictUpdate(entry);
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await _clearAllDataInTransaction();
    });
  }

  Future<void> importJson(Map<String, dynamic> payload) async {
    await transaction(() async {
      await _clearAllDataInTransaction();
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

  Future<void> importBackupV2(Map<String, dynamic> payload) async {
    final backup = BackupPayloadV2.fromJson(payload);
    if (backup.formatVersion != 2) {
      throw const BackupRestoreException('Unsupported backup format version.');
    }

    await transaction(() async {
      await _clearAllDataInTransaction();

      final accountIdMap = <int, int>{};
      final categoryIdMap = <int, int>{};

      final settings = await _settingsRow();
      await update(appSettingsTable).replace(
        settings.copyWith(
          currency: backup.settings.currency,
          themeMode: backup.settings.themeMode ?? settings.themeMode,
          demoSeeded: true,
        ),
      );

      for (final category in backup.categories) {
        final newId = await into(categories).insert(
          CategoriesCompanion.insert(
            name: category.name,
            type: Value(category.type),
            colorValue: Value(category.colorValue),
            iconName: Value(category.iconName),
            monthlyBudget: Value(category.monthlyBudget),
          ),
        );
        categoryIdMap[category.sourceId] = newId;
      }
      if (backup.categories.isNotEmpty &&
          categoryIdMap.length != backup.categories.length) {
        throw const BackupRestoreException(
          'Category mapping failed during backup restore.',
        );
      }

      for (final account in backup.accounts) {
        final newId = await into(accounts).insert(
          AccountsCompanion.insert(
            name: account.name,
            initialBalance: Value(account.initialBalance),
            currentBalance: Value(account.currentBalance),
            colorValue: Value(account.colorValue),
            createdAt: Value(_date(account.createdAt) ?? DateTime.now()),
          ),
        );
        accountIdMap[account.sourceId] = newId;
      }

      for (final task in backup.tasks) {
        await into(tasks).insert(
          TasksCompanion.insert(
            title: task.title,
            description: Value(task.description),
            dueDate: Value(_date(task.dueDate)),
            reminderAt: Value(_date(task.reminderAt)),
            priority: Value(task.priority),
            tags: Value(task.tags),
            isCompleted: Value(task.isCompleted),
            createdAt: Value(_date(task.createdAt) ?? DateTime.now()),
            updatedAt: Value(_date(task.updatedAt) ?? DateTime.now()),
            recurrencePattern: Value(task.recurrencePattern),
            recurrenceParentId: Value(task.recurrenceParentId),
          ),
        );
      }

      for (final event in backup.events) {
        final start = _date(event.startTime) ?? DateTime.now();
        await into(calendarEvents).insert(
          CalendarEventsCompanion.insert(
            title: event.title,
            description: Value(event.description),
            date: _date(event.date) ?? start,
            startTime: start,
            endTime: _date(event.endTime) ?? start.add(const Duration(hours: 1)),
            reminderAt: Value(_date(event.reminderAt)),
            createdAt: Value(_date(event.createdAt) ?? DateTime.now()),
            updatedAt: Value(_date(event.updatedAt) ?? DateTime.now()),
          ),
        );
      }

      for (final tx in backup.transactions) {
        final remappedAccountId = _remapAccountId(
          sourceAccountId: tx.accountId,
          map: accountIdMap,
          transactionSourceId: tx.sourceId,
          fieldName: 'accountId',
        );
        final remappedTransferTargetId = _remapAccountId(
          sourceAccountId: tx.transferTargetAccountId,
          map: accountIdMap,
          transactionSourceId: tx.sourceId,
          fieldName: 'transferTargetAccountId',
        );

        await into(financeEntries).insert(
          FinanceEntriesCompanion.insert(
            title: tx.title,
            amount: tx.amount,
            category: Value(tx.category),
            date: _date(tx.date) ?? DateTime.now(),
            note: Value(tx.note),
            type: Value(tx.type),
            createdAt: Value(_date(tx.createdAt) ?? DateTime.now()),
            updatedAt: Value(_date(tx.updatedAt) ?? DateTime.now()),
            accountId: Value(remappedAccountId),
            transferTargetAccountId: Value(remappedTransferTargetId),
          ),
        );
      }

      await recalculateAccountBalances();
    });
  }

  Future<void> _clearAllDataInTransaction() async {
    await delete(tasks).go();
    await delete(calendarEvents).go();
    await delete(financeEntries).go();
    await delete(categories).go();
    await delete(accounts).go();
    await delete(appSettingsTable).go();
    await into(appSettingsTable).insert(
      const AppSettingsTableCompanion(
        currency: Value(AppConstants.defaultCurrency),
        themeMode: Value('system'),
        demoSeeded: Value(true),
      ),
    );
  }

  int? _remapAccountId({
    required int? sourceAccountId,
    required Map<int, int> map,
    required int transactionSourceId,
    required String fieldName,
  }) {
    if (sourceAccountId == null) return null;
    final remapped = map[sourceAccountId];
    if (remapped == null) {
      throw BackupRestoreException(
        'Missing account mapping for transaction $transactionSourceId ($fieldName -> $sourceAccountId).',
      );
    }
    return remapped;
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

  Future<void> _seedAccounts() async {
    final existing = await select(accounts).get();
    if (existing.isNotEmpty) return;

    await batch((batch) {
      batch.insertAll(accounts, [
        AccountsCompanion.insert(
          name: 'Bank',
          initialBalance: const Value(50000.0),
          currentBalance: const Value(50000.0),
          colorValue: const Value(0xFF286C63),
        ),
        AccountsCompanion.insert(
          name: 'Cash',
          initialBalance: const Value(5000.0),
          currentBalance: const Value(5000.0),
          colorValue: const Value(0xFF4B66D3),
        ),
        AccountsCompanion.insert(
          name: 'Savings',
          initialBalance: const Value(200000.0),
          currentBalance: const Value(200000.0),
          colorValue: const Value(0xFFC77D2B),
        ),
      ]);
    });
  }

  Future<void> _seedFinanceEntries() async {
    if ((await select(financeEntries).get()).isNotEmpty) return;

    final allAccounts = await select(accounts).get();
    final bankAccount = allAccounts.firstWhere((a) => a.name == 'Bank',
        orElse: () => allAccounts.first);
    final cashAccount = allAccounts.firstWhere((a) => a.name == 'Cash',
        orElse: () => allAccounts.first);

    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(financeEntries, [
        FinanceEntriesCompanion.insert(
          title: 'Monthly salary',
          amount: 185000,
          category: const Value('Salary'),
          date: DateTime(now.year, now.month, 1),
          type: const Value('income'),
          accountId: Value(bankAccount.id),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Groceries',
          amount: 12600,
          category: const Value('Food'),
          date: now.subtract(const Duration(days: 2)),
          type: const Value('expense'),
          accountId: Value(cashAccount.id),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Internet bill',
          amount: 5900,
          category: const Value('Bills'),
          date: now.subtract(const Duration(days: 4)),
          type: const Value('expense'),
          accountId: Value(bankAccount.id),
        ),
        FinanceEntriesCompanion.insert(
          title: 'Train pass',
          amount: 3200,
          category: const Value('Transport'),
          date: now.subtract(const Duration(days: 7)),
          type: const Value('expense'),
          accountId: Value(cashAccount.id),
        ),
      ]);
    });
  }

  Stream<List<Account>> watchAccounts() {
    return (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<int> saveAccount(AccountsCompanion entry) async {
    return transaction(() async {
      final id = await into(accounts).insertOnConflictUpdate(entry);
      await recalculateAccountBalances();
      return id;
    });
  }

  Future<void> deleteAccount(int id) async {
    await transaction(() async {
      await (delete(accounts)..where((a) => a.id.equals(id))).go();
      await (delete(financeEntries)
            ..where((t) =>
                t.accountId.equals(id) |
                t.transferTargetAccountId.equals(id)))
          .go();
      await recalculateAccountBalances();
    });
  }

  Future<void> recalculateAccountBalances() async {
    await transaction(() async {
      final allAccounts = await select(accounts).get();
      final allEntries = await select(financeEntries).get();

      for (final account in allAccounts) {
        var balance = account.initialBalance;
        for (final entry in allEntries) {
          if (entry.accountId == account.id) {
            if (entry.type == 'income') {
              balance += entry.amount;
            } else if (entry.type == 'expense' || entry.type == 'transfer') {
              balance -= entry.amount;
            }
          }
          if (entry.transferTargetAccountId == account.id &&
              entry.type == 'transfer') {
            balance += entry.amount;
          }
        }
        await (update(accounts)..where((a) => a.id.equals(account.id))).write(
          AccountsCompanion(currentBalance: Value(balance)),
        );
      }
    });
  }

  Future<int> saveFinanceEntryWithBalance(FinanceEntriesCompanion entry) async {
    return transaction(() async {
      final id = await into(financeEntries).insertOnConflictUpdate(entry);
      await recalculateAccountBalances();
      return id;
    });
  }

  Future<void> deleteFinanceEntryWithBalance(int id) async {
    await transaction(() async {
      await (delete(financeEntries)..where((t) => t.id.equals(id))).go();
      await recalculateAccountBalances();
    });
  }
}

class BackupRestoreException implements Exception {
  const BackupRestoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
