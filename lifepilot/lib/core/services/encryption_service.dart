import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyName = 'lifepilot_db_key';
  static const _storage = FlutterSecureStorage();

  /// Retrieves the existing database key or generates a new 256-bit key if none exists.
  static Future<String> getOrGenerateKey() async {
    try {
      final key = await _storage.read(key: _keyName);
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (_) {
      // Fallback if secure storage read encounters issues
    }

    final newKey = generateSecureKey();
    try {
      await saveKey(newKey);
    } catch (_) {
      // Key generated but secure storage write failed (e.g. in test/simulator environment)
    }
    return newKey;
  }

  /// Generates a cryptographically secure 256-bit (32-byte) key.
  static String generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Saves a key to secure storage.
  static Future<void> saveKey(String key) async {
    await _storage.write(key: _keyName, value: key);
  }

  /// Rotates the key in secure storage.
  static Future<void> rotateKey(String newKey) async {
    await saveKey(newKey);
  }
}
