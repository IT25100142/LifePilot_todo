import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const String _backupFormatVersion = 'lifepilot-backup-v1';
const String _backupKdf = 'PBKDF2-HMAC-SHA256';
const String _backupCipher = 'AES-256-GCM';
const int _pbkdf2Iterations = 100000;
const int _saltLength = 16;
const int _nonceLength = 12;
const int _keyLength = 32;
const int _macLength = 16;

class BackupCryptoException implements Exception {
  const BackupCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<Uint8List> encryptBackupJson({
  required String json,
  required String password,
}) async {
  final salt = _secureRandomBytes(_saltLength);
  final nonce = _secureRandomBytes(_nonceLength);
  final secretKey = await _deriveKey(password, salt);
  final aesGcm = AesGcm.with256bits();

  final encrypted = await aesGcm.encrypt(
    utf8.encode(json),
    secretKey: secretKey,
    nonce: nonce,
  );

  final payload = <String, dynamic>{
    'format': _backupFormatVersion,
    'kdf': _backupKdf,
    'iterations': _pbkdf2Iterations,
    'cipher': _backupCipher,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
    'ciphertext': base64Encode(encrypted.cipherText),
    'mac': base64Encode(encrypted.mac.bytes),
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
}

List<int> _secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

Future<String> decryptBackupJson({
  required Uint8List bytes,
  required String password,
}) async {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const BackupCryptoException('Invalid backup file format.');
    }
    _validateContainer(decoded);

    final salt = base64Decode(decoded['salt'] as String);
    final nonce = base64Decode(decoded['nonce'] as String);
    final cipherText = base64Decode(decoded['ciphertext'] as String);
    final macBytes = base64Decode(decoded['mac'] as String);
    final secretKey = await _deriveKey(password, salt);
    final aesGcm = AesGcm.with256bits();

    final clearBytes = await aesGcm.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      ),
      secretKey: secretKey,
    );

    return utf8.decode(clearBytes);
  } on BackupCryptoException {
    rethrow;
  } on SecretBoxAuthenticationError {
    throw const BackupCryptoException(
      'Wrong password or corrupted backup file.',
    );
  } on FormatException {
    throw const BackupCryptoException('Invalid backup file format.');
  } catch (_) {
    throw const BackupCryptoException('Unable to decrypt backup file.');
  }
}

Future<SecretKey> _deriveKey(String password, List<int> salt) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: _keyLength * 8,
  );

  final seed = SecretKey(utf8.encode(password));
  return pbkdf2.deriveKey(secretKey: seed, nonce: salt);
}

void _validateContainer(Map<String, dynamic> payload) {
  if (payload['format'] != _backupFormatVersion ||
      payload['kdf'] != _backupKdf ||
      payload['cipher'] != _backupCipher ||
      payload['iterations'] != _pbkdf2Iterations) {
    throw const BackupCryptoException('Invalid backup file format.');
  }

  final salt = payload['salt'];
  final nonce = payload['nonce'];
  final ciphertext = payload['ciphertext'];
  final mac = payload['mac'];
  if (salt is! String || nonce is! String || ciphertext is! String || mac is! String) {
    throw const BackupCryptoException('Invalid backup file format.');
  }

  try {
    if (base64Decode(salt).length != _saltLength ||
        base64Decode(nonce).length != _nonceLength ||
        base64Decode(mac).length != _macLength ||
        base64Decode(ciphertext).isEmpty) {
      throw const BackupCryptoException('Invalid backup file format.');
    }
  } on FormatException {
    throw const BackupCryptoException('Invalid backup file format.');
  }
}
