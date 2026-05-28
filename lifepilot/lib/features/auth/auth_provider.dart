import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends Notifier<bool> {
  final _localAuth = LocalAuthentication();
  late final SharedPreferences _prefs;
  String _hashedPin = '';

  @override
  bool build() {
    _init();
    return true; // starts locked
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final stored = _prefs.getString('secure_pin_hash');
      if (stored == null) {
        _hashedPin = await _hash('1420'); // master fallback PIN
        await _prefs.setString('secure_pin_hash', _hashedPin);
      } else {
        _hashedPin = stored;
      }
    } catch (_) {
      // Handle fallback for test or mock environments
      _hashedPin = await _hash('1420');
    }
  }

  Future<String> _hash(String pin) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(utf8.encode(pin));
    return base64Encode(hash.bytes);
  }

  Future<bool> verifyPin(String pin) async {
    if (_hashedPin.isEmpty) {
      await _init();
    }
    final enteredHash = await _hash(pin);
    if (enteredHash == _hashedPin) {
      state = false; // unlock
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometrically() async {
    try {
      final isAvailable =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Secure Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        state = false; // unlock
        return true;
      }
    } catch (_) {
      // Gracefully fail in testing/headless environments
    }
    return false;
  }

  void lock() {
    state = true;
  }

  void unlock() {
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
