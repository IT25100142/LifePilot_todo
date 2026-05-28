import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('importBackupV2 remaps account references and transfer links', () async {
    final payload = {
      'formatVersion': 2,
      'app': 'LifePilot',
      'exportedAt': DateTime.now().toIso8601String(),
      'dbSchemaVersion': 4,
      'settings': {
        'currency': 'USD',
        'themeMode': 'dark',
      },
      'tasks': <Map<String, dynamic>>[],
      'events': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
      'accounts': [
        {
          'sourceId': 10,
          'name': 'Bank',
          'initialBalance': 1000.0,
          'currentBalance': 1000.0,
          'colorValue': 1,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'sourceId': 20,
          'name': 'Cash',
          'initialBalance': 200.0,
          'currentBalance': 200.0,
          'colorValue': 2,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ],
      'transactions': [
        {
          'sourceId': 100,
          'title': 'ATM Transfer',
          'amount': 50.0,
          'category': 'Transfer',
          'date': DateTime.now().toIso8601String(),
          'note': '',
          'type': 'transfer',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'accountId': 10,
          'transferTargetAccountId': 20,
        }
      ],
    };

    await db.importBackupV2(payload);

    final accounts = await db.select(db.accounts).get();
    final entries = await db.select(db.financeEntries).get();

    expect(accounts.length, 2);
    expect(entries.length, 1);

    final byName = {for (final item in accounts) item.name: item.id};
    final tx = entries.single;
    expect(tx.accountId, byName['Bank']);
    expect(tx.transferTargetAccountId, byName['Cash']);

    final settings = await db.readSettings();
    expect(settings.currency, 'USD');
  });

  test('importBackupV2 rolls back fully on unresolved account mapping', () async {
    await db.saveTask(
      TasksCompanion.insert(
        title: 'Existing task',
        description: const Value('before import'),
      ),
    );

    final beforeTasks = await db.select(db.tasks).get();
    expect(beforeTasks.length, 1);

    final badPayload = {
      'formatVersion': 2,
      'app': 'LifePilot',
      'exportedAt': DateTime.now().toIso8601String(),
      'dbSchemaVersion': 4,
      'settings': {'currency': 'EUR'},
      'tasks': <Map<String, dynamic>>[],
      'events': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
      'accounts': [
        {
          'sourceId': 1,
          'name': 'Only Account',
          'initialBalance': 0.0,
          'currentBalance': 0.0,
          'colorValue': 1,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ],
      'transactions': [
        {
          'sourceId': 999,
          'title': 'Broken link',
          'amount': 10.0,
          'category': 'Other',
          'date': DateTime.now().toIso8601String(),
          'note': '',
          'type': 'expense',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'accountId': 2, // Missing map entry
          'transferTargetAccountId': null,
        }
      ],
    };

    expect(
      () => db.importBackupV2(badPayload),
      throwsA(isA<BackupRestoreException>()),
    );

    final afterTasks = await db.select(db.tasks).get();
    expect(afterTasks.length, 1, reason: 'transaction should rollback all changes');
  });
}
