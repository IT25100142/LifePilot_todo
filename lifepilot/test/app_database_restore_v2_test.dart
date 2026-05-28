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

  test('importBackupV2 complex fixture payload with transfers, budgets, mixed events, and balance reconciliation', () async {
    final complexPayload = {
      'formatVersion': 2,
      'app': 'LifePilot',
      'exportedAt': DateTime.now().toIso8601String(),
      'dbSchemaVersion': 4,
      'settings': {
        'currency': 'EUR',
        'themeMode': 'system',
      },
      'categories': [
        {
          'sourceId': 301,
          'name': 'Groceries',
          'type': 'finance',
          'colorValue': 0xFF123456,
          'iconName': 'shopping_cart',
          'monthlyBudget': 450.0,
        },
        {
          'sourceId': 302,
          'name': 'Work Tasks',
          'type': 'task',
          'colorValue': 0xFF654321,
          'iconName': 'work',
          'monthlyBudget': null,
        }
      ],
      'accounts': [
        {
          'sourceId': 11,
          'name': 'Checking Wallet',
          'initialBalance': 1500.0,
          'currentBalance': 1500.0,
          'colorValue': 111,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'sourceId': 22,
          'name': 'High-Yield Savings',
          'initialBalance': 10000.0,
          'currentBalance': 10000.0,
          'colorValue': 222,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ],
      'transactions': [
        {
          'sourceId': 1001,
          'title': 'Salary Deposit',
          'amount': 2500.0,
          'category': 'Salary',
          'date': DateTime.now().toIso8601String(),
          'note': 'Monthly wage',
          'type': 'income',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'accountId': 11,
          'transferTargetAccountId': null,
        },
        {
          'sourceId': 1002,
          'title': 'Groceries Expense',
          'amount': 120.0,
          'category': 'Groceries',
          'date': DateTime.now().toIso8601String(),
          'note': 'Weekly food prep',
          'type': 'expense',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'accountId': 11,
          'transferTargetAccountId': null,
        },
        {
          'sourceId': 1003,
          'title': 'Transfer to Savings',
          'amount': 1000.0,
          'category': 'Transfer',
          'date': DateTime.now().toIso8601String(),
          'note': 'Save for house',
          'type': 'transfer',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'accountId': 11,
          'transferTargetAccountId': 22,
        },
      ],
      'tasks': [
        {
          'sourceId': 401,
          'title': 'One-off Task Completed',
          'description': 'Description for task 1',
          'dueDate': DateTime.now().toIso8601String(),
          'reminderAt': null,
          'priority': 'high',
          'tags': 'Work',
          'isCompleted': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'recurrencePattern': null,
          'recurrenceParentId': null,
        },
        {
          'sourceId': 402,
          'title': 'Daily Exercise Recurring',
          'description': 'Cardio',
          'dueDate': null,
          'reminderAt': null,
          'priority': 'low',
          'tags': 'Health',
          'isCompleted': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'recurrencePattern': 'daily',
          'recurrenceParentId': null,
        },
      ],
      'events': [
        {
          'sourceId': 501,
          'title': 'Important Planning Meeting',
          'description': 'Sync up with the team',
          'date': DateTime.now().toIso8601String(),
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'reminderAt': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ],
    };

    await db.importBackupV2(complexPayload);

    // Assert Settings
    final settings = await db.readSettings();
    expect(settings.currency, 'EUR');
    expect(settings.themeMode, 'system');

    // Assert Accounts & Balances
    final dbAccounts = await db.select(db.accounts).get();
    expect(dbAccounts.length, 2);

    final checking = dbAccounts.firstWhere((a) => a.name == 'Checking Wallet');
    final savings = dbAccounts.firstWhere((a) => a.name == 'High-Yield Savings');

    // Checking Wallet balance: 1500.0 + 2500.0 (income) - 120.0 (expense) - 1000.0 (transfer source) = 2880.0
    expect(checking.initialBalance, 1500.0);
    expect(checking.currentBalance, 2880.0);

    // High-Yield Savings balance: 10000.0 + 1000.0 (transfer target) = 11000.0
    expect(savings.initialBalance, 10000.0);
    expect(savings.currentBalance, 11000.0);

    // Assert Categories & Budgets
    final dbCategories = await db.select(db.categories).get();
    expect(dbCategories.length, 2);
    final groceries = dbCategories.firstWhere((c) => c.name == 'Groceries');
    expect(groceries.monthlyBudget, 450.0);
    expect(groceries.type, 'finance');

    final work = dbCategories.firstWhere((c) => c.name == 'Work Tasks');
    expect(work.monthlyBudget, isNull);
    expect(work.type, 'task');

    // Assert Transactions
    final dbTx = await db.select(db.financeEntries).get();
    expect(dbTx.length, 3);

    final salary = dbTx.firstWhere((t) => t.title == 'Salary Deposit');
    expect(salary.accountId, checking.id);
    expect(salary.transferTargetAccountId, isNull);
    expect(salary.amount, 2500.0);
    expect(salary.type, 'income');

    final transfer = dbTx.firstWhere((t) => t.title == 'Transfer to Savings');
    expect(transfer.accountId, checking.id);
    expect(transfer.transferTargetAccountId, savings.id);
    expect(transfer.amount, 1000.0);
    expect(transfer.type, 'transfer');

    // Assert Tasks
    final dbTasks = await db.select(db.tasks).get();
    expect(dbTasks.length, 2);

    final oneOff = dbTasks.firstWhere((t) => t.title == 'One-off Task Completed');
    expect(oneOff.isCompleted, isTrue);
    expect(oneOff.recurrencePattern, isNull);

    final recurring = dbTasks.firstWhere((t) => t.title == 'Daily Exercise Recurring');
    expect(recurring.isCompleted, isFalse);
    expect(recurring.recurrencePattern, 'daily');

    // Assert Events
    final dbEvents = await db.select(db.calendarEvents).get();
    expect(dbEvents.length, 1);
    expect(dbEvents.single.title, 'Important Planning Meeting');
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
