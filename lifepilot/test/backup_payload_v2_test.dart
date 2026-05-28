import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/models/backup_payload_v2.dart';

void main() {
  group('BackupPayloadV2 Serialization & Edge Cases', () {
    test(
      'BackupPayloadV2 serialization round-trip keeps relational fields',
      () {
        const payload = BackupPayloadV2(
          formatVersion: 2,
          app: 'LifePilot',
          exportedAt: '2026-01-01T00:00:00.000Z',
          dbSchemaVersion: 4,
          settings: BackupSettingsV2(currency: 'LKR', themeMode: 'dark'),
          tasks: [
            BackupTaskV2(
              sourceId: 1,
              title: 'Task',
              description: 'Desc',
              dueDate: '2026-01-02T00:00:00.000Z',
              reminderAt: null,
              priority: 'high',
              tags: 'Work',
              isCompleted: false,
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
              recurrencePattern: null,
              recurrenceParentId: null,
            ),
          ],
          events: [
            BackupEventV2(
              sourceId: 2,
              title: 'Event',
              description: 'Desc',
              date: '2026-01-02T00:00:00.000Z',
              startTime: '2026-01-02T08:00:00.000Z',
              endTime: '2026-01-02T09:00:00.000Z',
              reminderAt: null,
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
            ),
          ],
          categories: [
            BackupCategoryV2(
              sourceId: 3,
              name: 'Food',
              type: 'finance',
              colorValue: 123,
              iconName: 'label',
              monthlyBudget: 1000,
            ),
          ],
          accounts: [
            BackupAccountV2(
              sourceId: 4,
              name: 'Cash',
              initialBalance: 50,
              currentBalance: 100,
              colorValue: 123,
              createdAt: '2026-01-01T00:00:00.000Z',
            ),
          ],
          transactions: [
            BackupTransactionV2(
              sourceId: 5,
              title: 'Transfer',
              amount: 20,
              category: 'Transfer',
              date: '2026-01-02T00:00:00.000Z',
              note: '',
              type: 'transfer',
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
              accountId: 4,
              transferTargetAccountId: 4,
            ),
          ],
        );

        final encoded = payload.toJson();
        final decoded = BackupPayloadV2.fromJson(encoded);

        expect(decoded.formatVersion, 2);
        expect(decoded.settings.currency, 'LKR');
        expect(decoded.accounts.single.sourceId, 4);
        expect(decoded.transactions.single.accountId, 4);
        expect(decoded.transactions.single.transferTargetAccountId, 4);
      },
    );

    test(
      'fromJson parses empty arrays and handles missing settings gracefully',
      () {
        final json = <String, dynamic>{'formatVersion': 2, 'app': 'LifePilot'};

        final payload = BackupPayloadV2.fromJson(json);

        expect(payload.formatVersion, 2);
        expect(payload.app, 'LifePilot');
        expect(payload.tasks, isEmpty);
        expect(payload.events, isEmpty);
        expect(payload.categories, isEmpty);
        expect(payload.accounts, isEmpty);
        expect(payload.transactions, isEmpty);
        expect(
          payload.settings.currency,
          'LKR',
        ); // Default currency code fallback
        expect(payload.settings.themeMode, isNull);
      },
    );

    test(
      'BackupSettingsV2 fromJson handles null/missing fields gracefully',
      () {
        final settings = BackupSettingsV2.fromJson({});
        expect(settings.currency, 'LKR');
        expect(settings.themeMode, isNull);
      },
    );

    test('BackupTaskV2 fromJson applies fallback defaults on missing keys', () {
      final task = BackupTaskV2.fromJson({});
      expect(task.sourceId, 0);
      expect(task.title, 'Imported task');
      expect(task.description, '');
      expect(task.dueDate, isNull);
      expect(task.reminderAt, isNull);
      expect(task.priority, 'medium');
      expect(task.tags, '');
      expect(task.isCompleted, isFalse);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
      expect(task.recurrencePattern, isNull);
      expect(task.recurrenceParentId, isNull);
    });

    test(
      'BackupEventV2 fromJson applies fallback defaults on missing keys',
      () {
        final event = BackupEventV2.fromJson({});
        expect(event.sourceId, 0);
        expect(event.title, 'Imported event');
        expect(event.description, '');
        expect(event.reminderAt, isNull);
        expect(event.date, isNotNull);
        expect(event.startTime, isNotNull);
        expect(event.endTime, isNotNull);
      },
    );

    test(
      'BackupCategoryV2 fromJson applies fallback defaults on missing keys',
      () {
        final category = BackupCategoryV2.fromJson({});
        expect(category.sourceId, 0);
        expect(category.name, 'Category');
        expect(category.type, 'both');
        expect(category.colorValue, 0xFF286C63);
        expect(category.iconName, 'label');
        expect(category.monthlyBudget, isNull);
      },
    );

    test(
      'BackupAccountV2 fromJson applies fallback defaults on missing keys',
      () {
        final account = BackupAccountV2.fromJson({});
        expect(account.sourceId, 0);
        expect(account.name, 'Account');
        expect(account.initialBalance, 0.0);
        expect(account.currentBalance, 0.0);
        expect(account.colorValue, 0xFF286C63);
        expect(account.createdAt, isNotNull);
      },
    );

    test(
      'BackupTransactionV2 fromJson applies fallback defaults on missing keys',
      () {
        final tx = BackupTransactionV2.fromJson({});
        expect(tx.sourceId, 0);
        expect(tx.title, 'Imported transaction');
        expect(tx.amount, 0.0);
        expect(tx.category, 'Other');
        expect(tx.date, isNotNull);
        expect(tx.note, '');
        expect(tx.type, 'expense');
        expect(tx.accountId, isNull);
        expect(tx.transferTargetAccountId, isNull);
      },
    );
  });
}
