import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyService {
  static const _keyName = 'lifepilot_db_key';
  static const _storage = FlutterSecureStorage();

  static Future<String> getOrGenerateKey() async {
    try {
      final existingKey = await _storage.read(key: _keyName);
      if (existingKey != null && existingKey.isNotEmpty) {
        return existingKey;
      }
    } catch (_) {
      // Fallback if secure storage read encounters issues
    }

    final newKey = _generateSecureKey();
    try {
      await _storage.write(key: _keyName, value: newKey);
    } catch (_) {
      // Key generated but secure storage write failed (e.g., in some simulator environments).
      // We still return the key so the database can run.
    }
    return newKey;
  }

  static String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
