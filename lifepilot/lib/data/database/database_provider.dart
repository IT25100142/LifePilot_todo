import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/encryption_provider.dart';
import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final encryptionService = ref.watch(encryptionServiceProvider);
  final database = AppDatabase(encryptionService);
  ref.onDispose(database.close);
  return database;
});

final manualSeedDataProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  await database.ensureSeedData();
});
