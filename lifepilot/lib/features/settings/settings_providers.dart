import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/life_pilot_currency.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

class SettingsState {
  const SettingsState({required this.themeMode, required this.currency});

  final ThemeMode themeMode;
  final String currency;
}

final settingsStreamProvider = StreamProvider<AppSettingsTableData>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchSettings();
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );

final activeCurrencyCodeProvider = Provider<String>((ref) {
  final configured = ref
      .watch(settingsControllerProvider)
      .valueOrNull
      ?.currency;
  return currencyFromCode(configured).code;
});

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final database = ref.watch(appDatabaseProvider);
    final settings = await database.readSettings();
    ref.listen(settingsStreamProvider, (_, next) {
      next.whenData((value) {
        state = AsyncData(_fromData(value));
      });
    });
    return _fromData(settings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final database = ref.read(appDatabaseProvider);
    await database.updateThemeMode(mode.name);
  }

  Future<void> setCurrency(String currency) async {
    final clean = currencyFromCode(currency).code;
    final database = ref.read(appDatabaseProvider);
    await database.updateCurrency(clean);
  }

  SettingsState _fromData(AppSettingsTableData data) {
    return SettingsState(
      themeMode: switch (data.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      currency: currencyFromCode(
        data.currency.isEmpty ? AppConstants.defaultCurrency : data.currency,
      ).code,
    );
  }
}
