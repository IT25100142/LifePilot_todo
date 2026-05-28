import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_provider.dart';
import 'export_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ExportService(database);
});
