import 'dart:convert';
import 'dart:math' as math;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricGate {
  // A true runtime memory gate that cannot be cleared by widget unmounts
  static bool _nativePromptActiveOrPassed = false;
}

class AuthState {
  const AuthState({
    required this.isLocked,
    required this.isFirstTimeLaunch,
    required this.isRecovering,
    this.recoveryKey,
  });

  final bool isLocked;
  final bool isFirstTimeLaunch;
  final bool isRecovering;
  final String? recoveryKey;

  AuthState copyWith({
    bool? isLocked,
    bool? isFirstTimeLaunch,
    bool? isRecovering,
    String? recoveryKey,
  }) {
    return AuthState(
      isLocked: isLocked ?? this.isLocked,
      isFirstTimeLaunch: isFirstTimeLaunch ?? this.isFirstTimeLaunch,
      isRecovering: isRecovering ?? this.isRecovering,
      recoveryKey: recoveryKey ?? this.recoveryKey,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _localAuth = LocalAuthentication();
  late final SharedPreferences _prefs;
  String _hashedPin = '';
  String _hashedRecoveryKey = '';

  @override
  AuthState build() {
    _init();
    return const AuthState(
      isLocked: true,
      isFirstTimeLaunch: false,
      isRecovering: false,
    );
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final hasPin = _prefs.containsKey('secure_pin_hash');
      final hasUsername = _prefs.containsKey('secure_username');

      if (!hasPin || !hasUsername) {
        state = state.copyWith(isFirstTimeLaunch: true);
      } else {
        _hashedPin = _prefs.getString('secure_pin_hash') ?? '';
        _hashedRecoveryKey = _prefs.getString('secure_recovery_hash') ?? '';
        state = state.copyWith(isFirstTimeLaunch: false);
      }
    } catch (_) {
      // Handle fallback for test or mock environments
      state = state.copyWith(isFirstTimeLaunch: true);
    }
  }

  Future<String> _hash(String val) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(utf8.encode(val));
    return base64Encode(hash.bytes);
  }

  String _generateRecoveryKey() {
    final rand = math.Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String part1 = '';
    String part2 = '';
    for (int i = 0; i < 4; i++) {
      part1 += chars[rand.nextInt(chars.length)];
      part2 += chars[rand.nextInt(chars.length)];
    }
    return 'LP-$part1-$part2';
  }

  Future<void> createAccount(String username, String pin) async {
    if (_hashedPin.isEmpty) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {}
    }
    final pinHash = await _hash(pin);
    final recoveryKey = _generateRecoveryKey();
    final recoveryHash = await _hash(recoveryKey);

    try {
      await _prefs.setString('secure_username', username);
      await _prefs.setString('secure_pin_hash', pinHash);
      await _prefs.setString('secure_recovery_hash', recoveryHash);
    } catch (_) {}

    _hashedPin = pinHash;
    _hashedRecoveryKey = recoveryHash;

    state = state.copyWith(recoveryKey: recoveryKey);
  }

  void completeOnboarding() {
    state = state.copyWith(
      isFirstTimeLaunch: false,
      isLocked: false,
      recoveryKey: null,
    );
  }

  Future<bool> verifyPin(String pin) async {
    if (_hashedPin.isEmpty) {
      await _init();
    }
    final enteredHash = await _hash(pin);
    if (enteredHash == _hashedPin) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    return false;
  }

  Future<bool> resetPinWithRecoveryKey(String inputKey, String newPin) async {
    if (_hashedRecoveryKey.isEmpty) {
      await _init();
    }
    final cleanedKey = inputKey.trim().toUpperCase();
    final keyHash = await _hash(cleanedKey);

    if (keyHash == _hashedRecoveryKey) {
      final pinHash = await _hash(newPin);
      try {
        await _prefs.setString('secure_pin_hash', pinHash);
      } catch (_) {}
      _hashedPin = pinHash;
      state = state.copyWith(
        isLocked: false,
        isRecovering: false,
        isFirstTimeLaunch: false,
      );
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometrically() async {
    if (ref.read(authSessionProvider) ||
        BiometricGate._nativePromptActiveOrPassed) {
      return false;
    }
    BiometricGate._nativePromptActiveOrPassed = true;
    try {
      final isAvailable =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        BiometricGate._nativePromptActiveOrPassed = false;
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Secure Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        ref.read(authSessionProvider.notifier).markAsUnlocked();
        state = state.copyWith(isLocked: false);
        return true;
      }
    } catch (_) {
      // Gracefully fail in testing/headless environments
    } finally {
      if (state.isLocked) {
        BiometricGate._nativePromptActiveOrPassed = false;
      }
    }
    return false;
  }

  void enterRecovery() {
    state = state.copyWith(isRecovering: true);
  }

  void exitRecovery() {
    state = state.copyWith(isRecovering: false);
  }

  void lock() {
    state = state.copyWith(isLocked: true);
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void markAsUnlocked() {
    state = true;
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, bool>(
  AuthSessionNotifier.new,
);
