import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/models/backup_summary.dart';

void main() {
  group('BackupSummary Unit Tests', () {
    test('Constructor populates all fields correctly and applies defaults', () {
      final now = DateTime.now();
      final summary = BackupSummary(
        formatVersion: 2,
        exportedAt: now,
        taskCount: 15,
        eventCount: 3,
        accountCount: 4,
        transactionCount: 42,
        currency: 'USD',
        dbSchemaVersion: 4,
      );

      expect(summary.formatVersion, 2);
      expect(summary.exportedAt, now);
      expect(summary.taskCount, 15);
      expect(summary.eventCount, 3);
      expect(summary.accountCount, 4);
      expect(summary.transactionCount, 42);
      expect(summary.currency, 'USD');
      expect(summary.dbSchemaVersion, 4);
      expect(summary.isLegacy, isFalse);
    });

    test('isLegacy defaults to false but can be set to true', () {
      final summary = BackupSummary(
        formatVersion: 1,
        exportedAt: DateTime.now(),
        taskCount: 5,
        eventCount: 0,
        accountCount: 0,
        transactionCount: 10,
        isLegacy: true,
      );

      expect(summary.isLegacy, isTrue);
      expect(summary.formatVersion, 1);
    });
  });
}
