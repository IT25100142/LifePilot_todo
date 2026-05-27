import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import '../../data/database/app_database.dart';

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

  Future<Map<String, dynamic>> _payload(String currency) async {
    final tasks = await database.select(database.tasks).get();
    final events = await database.select(database.calendarEvents).get();
    final entries = await database.select(database.financeEntries).get();
    final categories = await database.select(database.categories).get();

    return {
      'app': 'LifePilot',
      'exportedAt': DateTime.now().toIso8601String(),
      'currency': currency,
      'tasks': [for (final item in tasks) item.toJson()],
      'events': [for (final item in events) item.toJson()],
      'transactions': [for (final item in entries) item.toJson()],
      'categories': [for (final item in categories) item.toJson()],
    };
  }
}
