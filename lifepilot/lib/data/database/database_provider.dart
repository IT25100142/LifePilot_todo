import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final databaseKeyProvider = Provider<String>((ref) {
  throw UnimplementedError('databaseKeyProvider must be overridden in main()');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final key = ref.watch(databaseKeyProvider);
  final database = AppDatabase.defaults(key);
  ref.onDispose(database.close);
  return database;
});

final seedDataProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  await database.ensureSeedData();
});
