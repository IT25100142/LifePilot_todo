import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/models/backup_summary.dart';
import 'package:lifepilot/core/services/export_provider.dart';
import 'package:lifepilot/core/services/export_service.dart';
import 'package:lifepilot/data/database/app_database.dart';
import 'package:lifepilot/data/database/database_provider.dart';
import 'package:lifepilot/features/settings/settings_screen.dart';

class FakeExportService implements ExportService {
  FakeExportService({
    required this.database,
    this.prepareImportResult,
    this.prepareImportError,
  });

  @override
  final AppDatabase database;

  final PreparedBackupImport? prepareImportResult;
  final Object? prepareImportError;

  int prepareCallCount = 0;
  int applyCallCount = 0;
  String? lastPasswordPrompted;
  PreparedBackupImport? appliedImport;

  @override
  Future<PreparedBackupImport?> prepareEncryptedBackupImport({
    required String password,
  }) async {
    prepareCallCount++;
    lastPasswordPrompted = password;
    if (prepareImportError != null) {
      throw prepareImportError!;
    }
    return prepareImportResult;
  }

  @override
  Future<void> applyPreparedBackupImport(PreparedBackupImport prepared) async {
    applyCallCount++;
    appliedImport = prepared;
  }

  @override
  Future<void> exportJson(String currency) async {}

  @override
  Future<void> exportEncryptedBackup({
    required String currency,
    required String password,
  }) async {}

  @override
  Future<void> exportCsv() async {}

  @override
  Future<bool> importJson() async => true;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'Restore workflow - entering valid password reveals summary dialog',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final exportDate = DateTime(2026, 5, 28, 12, 0);
      final summary = BackupSummary(
        formatVersion: 2,
        exportedAt: exportDate,
        taskCount: 12,
        eventCount: 4,
        accountCount: 3,
        transactionCount: 25,
        currency: 'USD',
        dbSchemaVersion: 4,
      );

      final fakeExportService = FakeExportService(
        database: db,
        prepareImportResult: PreparedBackupImport(
          summary: summary,
          payload: const {},
          route: BackupImportRoute.v2,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exportServiceProvider.overrideWithValue(fakeExportService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Find and tap the "Import Encrypted Backup" button
      final importButton = find.text('Import Encrypted Backup');
      expect(importButton, findsOneWidget);
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      // 2. The password dialog should appear
      expect(find.text('Unlock encrypted backup'), findsOneWidget);

      // 3. Enter password and submit
      final passwordField = find.widgetWithText(
        TextFormField,
        'Backup password',
      );
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'mypassword123');
      await tester.pumpAndSettle();

      final decryptButton = find.text('Decrypt');
      expect(decryptButton, findsOneWidget);
      await tester.tap(decryptButton);
      await tester.pumpAndSettle();

      // 4. Verify password was forwarded
      expect(fakeExportService.prepareCallCount, 1);
      expect(fakeExportService.lastPasswordPrompted, 'mypassword123');
      // 5. The preflight confirmation dialog should appear with counts
      expect(find.text('Restore backup data?'), findsOneWidget);
      expect(find.text('Backup date: 28 May 2026'), findsOneWidget);
      expect(find.text('Tasks: 12'), findsOneWidget);
      expect(find.text('Events: 4'), findsOneWidget);
      expect(find.text('Accounts: 3'), findsOneWidget);
      expect(find.text('Transactions: 25'), findsOneWidget);
      expect(find.text('Currency: USD'), findsOneWidget);

      // 6. Dismiss dialog to clean up for subsequent tests
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Unmount widget tree to clean up active streams and timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Restore workflow - tapping Cancel on summary dialog aborts restore with zero database apply calls',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final summary = BackupSummary(
        formatVersion: 2,
        exportedAt: DateTime(2026, 5, 28),
        taskCount: 5,
        eventCount: 2,
        accountCount: 1,
        transactionCount: 10,
      );

      final fakeExportService = FakeExportService(
        database: db,
        prepareImportResult: PreparedBackupImport(
          summary: summary,
          payload: const {},
          route: BackupImportRoute.v2,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exportServiceProvider.overrideWithValue(fakeExportService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final importButton = find.text('Import Encrypted Backup');
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Backup password'),
        'pass',
      );
      await tester.tap(find.text('Decrypt'));
      await tester.pumpAndSettle();

      // Verify summary dialog is visible
      expect(find.text('Restore backup data?'), findsOneWidget);

      // Tap Cancel
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Restore backup data?'), findsNothing);

      // Verify no apply calls were made
      expect(fakeExportService.applyCallCount, 0);

      // Unmount widget tree to clean up active streams and timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Restore workflow - tapping Confirm (Replace Data) applies import and shows SnackBar',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final summary = BackupSummary(
        formatVersion: 2,
        exportedAt: DateTime(2026, 5, 28),
        taskCount: 5,
        eventCount: 2,
        accountCount: 1,
        transactionCount: 10,
      );

      final fakeExportService = FakeExportService(
        database: db,
        prepareImportResult: PreparedBackupImport(
          summary: summary,
          payload: const {'key': 'val'},
          route: BackupImportRoute.v2,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exportServiceProvider.overrideWithValue(fakeExportService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final importButton = find.text('Import Encrypted Backup');
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Backup password'),
        'pass',
      );
      await tester.tap(find.text('Decrypt'));
      await tester.pumpAndSettle();

      // Verify summary dialog is visible
      expect(find.text('Restore backup data?'), findsOneWidget);

      // Tap Replace Data
      final replaceButton = find.text('Replace Data');
      expect(replaceButton, findsOneWidget);
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Restore backup data?'), findsNothing);

      // Verify apply was called with the correct payload
      expect(fakeExportService.applyCallCount, 1);
      expect(fakeExportService.appliedImport?.payload, const {'key': 'val'});

      // Verify "Import complete" SnackBar is shown
      expect(find.text('Import complete'), findsOneWidget);

      // Unmount widget tree to clean up active streams and timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
