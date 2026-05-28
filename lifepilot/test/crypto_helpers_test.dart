import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/utils/crypto_helpers.dart';

void main() {
  test('encrypt/decrypt backup round-trip returns original JSON', () async {
    const password = 'strong-password-123';
    const jsonPayload =
        '{"app":"LifePilot","currency":"LKR","tasks":[{"id":1}]}';

    final encrypted = await encryptBackupJson(
      json: jsonPayload,
      password: password,
    );
    final decrypted = await decryptBackupJson(
      bytes: encrypted,
      password: password,
    );

    expect(decrypted, jsonPayload);
  });

  test('decrypt fails with wrong password', () async {
    final encrypted = await encryptBackupJson(
      json: '{"app":"LifePilot"}',
      password: 'correct-password',
    );

    expect(
      () => decryptBackupJson(bytes: encrypted, password: 'wrong-password'),
      throwsA(isA<BackupCryptoException>()),
    );
  });

  test('decrypt fails with malformed container', () async {
    final badBytes = Uint8List.fromList(
      utf8.encode(jsonEncode({'format': 'invalid-format', 'salt': 'abc'})),
    );

    expect(
      () => decryptBackupJson(bytes: badBytes, password: 'irrelevant'),
      throwsA(isA<BackupCryptoException>()),
    );
  });
}
