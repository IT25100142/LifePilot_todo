import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/database_key_service.dart';
import 'data/database/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final encryptionKey = await DatabaseKeyService.getOrGenerateKey();
  runApp(
    ProviderScope(
      overrides: [
        databaseKeyProvider.overrideWithValue(encryptionKey),
      ],
      child: const LifePilotApp(),
    ),
  );
}
