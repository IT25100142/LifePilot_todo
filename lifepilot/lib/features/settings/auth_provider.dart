import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricsEnabledProvider = StateProvider<bool>((ref) => true);

enum AppLockStatus { unlocked, locked, notSupported }

class AppLockNotifier extends Notifier<AppLockStatus> {
  final _auth = LocalAuthentication();

  @override
  AppLockStatus build() {
    if (kIsWeb) {
      return AppLockStatus.unlocked;
    }
    final enabled = ref.watch(biometricsEnabledProvider);
    if (!enabled) {
      return AppLockStatus.unlocked;
    }
    return AppLockStatus.locked;
  }

  void lock() {
    if (kIsWeb) return;
    final enabled = ref.read(biometricsEnabledProvider);
    if (enabled && state != AppLockStatus.notSupported) {
      state = AppLockStatus.locked;
    }
  }

  void unlock() {
    if (state != AppLockStatus.notSupported) {
      state = AppLockStatus.unlocked;
    }
  }

  Future<void> authenticate() async {
    if (kIsWeb) {
      state = AppLockStatus.unlocked;
      return;
    }
    final enabled = ref.read(biometricsEnabledProvider);
    if (!enabled) {
      state = AppLockStatus.unlocked;
      return;
    }

    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!isAvailable && !isDeviceSupported) {
        state = AppLockStatus.notSupported;
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access LifePilot',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        state = AppLockStatus.unlocked;
      }
    } catch (_) {
      // Fallback/remain locked on error/cancel
    }
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockStatus>(
  AppLockNotifier.new,
);
