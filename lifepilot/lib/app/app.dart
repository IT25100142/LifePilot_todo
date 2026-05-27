import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_providers.dart';
import 'router.dart';
import 'theme.dart';

class LifePilotApp extends ConsumerWidget {
  const LifePilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final themeMode = settings.valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'LifePilot',
      debugShowCheckedModeBanner: false,
      theme: LifePilotTheme.light(),
      darkTheme: LifePilotTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
