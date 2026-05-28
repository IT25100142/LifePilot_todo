import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass.dart';
import 'auth_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLockProvider.notifier).authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(appLockProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(appLockProvider.notifier).authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final theme = Theme.of(context);

    if (!lockState.isLocked) {
      return widget.child;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Keep base app rendered underneath the glass blur (gives high premium feel)
          widget.child,
          // Full-screen glass overlay
          Positioned.fill(
            child: GlassPanel(
              radius: 0,
              padding: const EdgeInsets.all(24),
              opacity: theme.brightness == Brightness.dark ? 0.38 : 0.62,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF286C63).withValues(alpha: 0.16),
                      radius: 54,
                      child: const Icon(
                        Icons.lock_person_outlined,
                        color: Color(0xFF286C63),
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LifePilot Secured',
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock with device biometrics to continue.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(appLockProvider.notifier).authenticate();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF286C63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      ),
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock Application'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
