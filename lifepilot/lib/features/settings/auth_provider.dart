import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricsEnabledProvider = StateProvider<bool>((ref) => true);

class AppLockState {
  AppLockState({required this.isLocked});
  final bool isLocked;
}

class AppLockNotifier extends Notifier<AppLockState> {
  final _auth = LocalAuthentication();

  @override
  AppLockState build() {
    final enabled = ref.watch(biometricsEnabledProvider);
    return AppLockState(isLocked: enabled);
  }

  void lock() {
    final enabled = ref.read(biometricsEnabledProvider);
    if (enabled) {
      state = AppLockState(isLocked: true);
    }
  }

  void unlock() {
    state = AppLockState(isLocked: false);
  }

  Future<void> authenticate() async {
    final enabled = ref.read(biometricsEnabledProvider);
    if (!enabled) {
      unlock();
      return;
    }

    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!isAvailable && !isDeviceSupported) {
        unlock();
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
        unlock();
      }
    } catch (_) {
      // Allow fallback on error/cancellation (unlocked or retain lock depending on retry)
    }
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);
