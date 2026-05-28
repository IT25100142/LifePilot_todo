import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import '../models/backup_payload_v2.dart';
import '../models/backup_summary.dart';
import '../utils/crypto_helpers.dart';
import '../../data/database/app_database.dart';

enum BackupImportRoute { v2, legacy }

class PreparedBackupImport {
  const PreparedBackupImport({
    required this.summary,
    required this.payload,
    required this.route,
  });

  final BackupSummary summary;
  final Map<String, dynamic> payload;
  final BackupImportRoute route;
}

class ExportService {
  ExportService(this.database);

  final AppDatabase database;

  Future<void> exportJson(String currency) async {
    final payload = await _payload(currency);
    final bytes = Uint8List.fromList(
      const JsonEncoder.withIndent('  ').convert(payload).codeUnits,
    );
    await FileSaver.instance.saveFile(
      name: 'lifepilot-export',
      bytes: bytes,
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
  }

  Future<void> exportEncryptedBackup({
    required String currency,
    required String password,
  }) async {
    final payload = await _payloadV2(currency);
    final json = const JsonEncoder.withIndent('  ').convert(payload.toJson());
    final bytes = await encryptBackupJson(json: json, password: password);
    await FileSaver.instance.saveFile(
      name: 'lifepilot-backup',
      bytes: bytes,
      fileExtension: 'lpbackup',
      mimeType: MimeType.other,
    );
  }

  Future<void> exportCsv() async {
    final tasks = await database.select(database.tasks).get();
    final events = await database.select(database.calendarEvents).get();
    final entries = await database.select(database.financeEntries).get();
    final rows = <List<Object?>>[
      [
        'section',
        'title',
        'amount',
        'category',
        'type',
        'date',
        'status',
        'note',
      ],
      for (final task in tasks)
        [
          'task',
          task.title,
          '',
          task.tags,
          task.priority,
          task.dueDate?.toIso8601String() ?? '',
          task.isCompleted ? 'completed' : 'open',
          task.description,
        ],
      for (final event in events)
        [
          'event',
          event.title,
          '',
          '',
          '',
          event.startTime.toIso8601String(),
          'scheduled',
          event.description,
        ],
      for (final entry in entries)
        [
          'transaction',
          entry.title,
          entry.amount,
          entry.category,
          entry.type,
          entry.date.toIso8601String(),
          '',
          entry.note,
        ],
    ];
    final bytes = Uint8List.fromList(
      const ListToCsvConverter().convert(rows).codeUnits,
    );
    await FileSaver.instance.saveFile(
      name: 'lifepilot-export',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<bool> importJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null) return false;
    final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    await database.importJson(payload);
    return true;
  }

  Future<PreparedBackupImport?> prepareEncryptedBackupImport({
    required String password,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lpbackup'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null) return null;

    final decryptedJson = await decryptBackupJson(
      bytes: bytes,
      password: password,
    );
    final decoded = jsonDecode(decryptedJson);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupCryptoException('Invalid backup file format.');
    }
    final formatVersion = (decoded['formatVersion'] as num?)?.toInt();
    if (formatVersion == 2) {
      final payload = BackupPayloadV2.fromJson(decoded);
      final exportedAt =
          DateTime.tryParse(payload.exportedAt) ?? DateTime.now();
      return PreparedBackupImport(
        summary: BackupSummary(
          formatVersion: payload.formatVersion,
          exportedAt: exportedAt,
          taskCount: payload.tasks.length,
          eventCount: payload.events.length,
          accountCount: payload.accounts.length,
          transactionCount: payload.transactions.length,
          currency: payload.settings.currency,
          dbSchemaVersion: payload.dbSchemaVersion,
        ),
        payload: decoded,
        route: BackupImportRoute.v2,
      );
    }

    if (_isLegacyPayload(decoded)) {
      final exportedAt =
          DateTime.tryParse(decoded['exportedAt'] as String? ?? '') ??
          DateTime.now();
      return PreparedBackupImport(
        summary: BackupSummary(
          formatVersion: 1,
          exportedAt: exportedAt,
          taskCount: (decoded['tasks'] as List<dynamic>? ?? const []).length,
          eventCount: (decoded['events'] as List<dynamic>? ?? const []).length,
          accountCount: 0,
          transactionCount:
              (decoded['transactions'] as List<dynamic>? ?? const []).length,
          currency: decoded['currency'] as String?,
          isLegacy: true,
        ),
        payload: decoded,
        route: BackupImportRoute.legacy,
      );
    }
    throw const BackupCryptoException('Invalid backup file format.');
  }

  Future<void> applyPreparedBackupImport(PreparedBackupImport prepared) async {
    switch (prepared.route) {
      case BackupImportRoute.v2:
        await database.importBackupV2(prepared.payload);
      case BackupImportRoute.legacy:
        await database.importJson(prepared.payload);
    }
  }

  bool _isLegacyPayload(Map<String, dynamic> payload) {
    return payload['tasks'] is List ||
        payload['events'] is List ||
        payload['transactions'] is List;
  }

  Future<BackupPayloadV2> _payloadV2(String currency) async {
    final tasks = await database.select(database.tasks).get();
    final events = await database.select(database.calendarEvents).get();
    final entries = await database.select(database.financeEntries).get();
    final categories = await database.select(database.categories).get();
    final accounts = await database.select(database.accounts).get();
    final settings = await database.readSettings();

    return BackupPayloadV2(
      formatVersion: 2,
      app: 'LifePilot',
      exportedAt: DateTime.now().toIso8601String(),
      dbSchemaVersion: database.schemaVersion,
      settings: BackupSettingsV2(
        currency: currency,
        themeMode: settings.themeMode,
      ),
      tasks: [
        for (final item in tasks)
          BackupTaskV2(
            sourceId: item.id,
            title: item.title,
            description: item.description,
            dueDate: item.dueDate?.toIso8601String(),
            reminderAt: item.reminderAt?.toIso8601String(),
            priority: item.priority,
            tags: item.tags,
            isCompleted: item.isCompleted,
            createdAt: item.createdAt.toIso8601String(),
            updatedAt: item.updatedAt.toIso8601String(),
            recurrencePattern: item.recurrencePattern,
            recurrenceParentId: item.recurrenceParentId,
          ),
      ],
      events: [
        for (final item in events)
          BackupEventV2(
            sourceId: item.id,
            title: item.title,
            description: item.description,
            date: item.date.toIso8601String(),
            startTime: item.startTime.toIso8601String(),
            endTime: item.endTime.toIso8601String(),
            reminderAt: item.reminderAt?.toIso8601String(),
            createdAt: item.createdAt.toIso8601String(),
            updatedAt: item.updatedAt.toIso8601String(),
          ),
      ],
      categories: [
        for (final item in categories)
          BackupCategoryV2(
            sourceId: item.id,
            name: item.name,
            type: item.type,
            colorValue: item.colorValue,
            iconName: item.iconName,
            monthlyBudget: item.monthlyBudget,
          ),
      ],
      accounts: [
        for (final item in accounts)
          BackupAccountV2(
            sourceId: item.id,
            name: item.name,
            initialBalance: item.initialBalance,
            currentBalance: item.currentBalance,
            colorValue: item.colorValue,
            createdAt: item.createdAt.toIso8601String(),
          ),
      ],
      transactions: [
        for (final item in entries)
          BackupTransactionV2(
            sourceId: item.id,
            title: item.title,
            amount: item.amount,
            category: item.category,
            date: item.date.toIso8601String(),
            note: item.note,
            type: item.type,
            createdAt: item.createdAt.toIso8601String(),
            updatedAt: item.updatedAt.toIso8601String(),
            accountId: item.accountId,
            transferTargetAccountId: item.transferTargetAccountId,
          ),
      ],
    );
  }

  Future<Map<String, dynamic>> _payload(String currency) async {
    final payload = await _payloadV2(currency);
    final json = payload.toJson();
    return {
      'app': json['app'],
      'exportedAt': json['exportedAt'],
      'currency': payload.settings.currency,
      'tasks': [
        for (final item in payload.tasks)
          {
            'title': item.title,
            'description': item.description,
            'dueDate': item.dueDate,
            'reminderAt': item.reminderAt,
            'priority': item.priority,
            'tags': item.tags,
            'isCompleted': item.isCompleted,
            'createdAt': item.createdAt,
            'updatedAt': item.updatedAt,
            'recurrencePattern': item.recurrencePattern,
            'recurrenceParentId': item.recurrenceParentId,
          },
      ],
      'events': [
        for (final item in payload.events)
          {
            'title': item.title,
            'description': item.description,
            'date': item.date,
            'startTime': item.startTime,
            'endTime': item.endTime,
            'reminderAt': item.reminderAt,
            'createdAt': item.createdAt,
            'updatedAt': item.updatedAt,
          },
      ],
      'transactions': [
        for (final item in payload.transactions)
          {
            'title': item.title,
            'amount': item.amount,
            'category': item.category,
            'date': item.date,
            'note': item.note,
            'type': item.type,
            'createdAt': item.createdAt,
            'updatedAt': item.updatedAt,
          },
      ],
      'categories': [
        for (final item in payload.categories)
          {
            'name': item.name,
            'type': item.type,
            'colorValue': item.colorValue,
            'iconName': item.iconName,
            'monthlyBudget': item.monthlyBudget,
          },
      ],
    };
  }
}
