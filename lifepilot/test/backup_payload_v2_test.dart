import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/models/backup_payload_v2.dart';

void main() {
  test('BackupPayloadV2 serialization round-trip keeps relational fields', () {
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
  });
}
