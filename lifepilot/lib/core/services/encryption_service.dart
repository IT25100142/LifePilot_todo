import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class EncryptionServiceBase {
  Future<String> getOrGenerateKey();
  String generateSecureKey();
  Future<void> saveKey(String key);
  Future<void> rotateKey(String newKey);
}

class EncryptionService implements EncryptionServiceBase {
  EncryptionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _keyName = 'lifepilot_db_key';

  @override
  Future<String> getOrGenerateKey() async {
    try {
      final key = await _storage.read(key: _keyName);
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (_) {
      debugPrint(
        'EncryptionService.getOrGenerateKey: Read from secure storage failed',
      );
    }

    final newKey = generateSecureKey();
    try {
      await saveKey(newKey);
    } catch (_) {
      debugPrint(
        'EncryptionService.getOrGenerateKey: Write to secure storage failed',
      );
    }
    return newKey;
  }

  @override
  String generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  @override
  Future<void> saveKey(String key) async {
    await _storage.write(key: _keyName, value: key);
  }

  @override
  Future<void> rotateKey(String newKey) async {
    await saveKey(newKey);
  }
}
