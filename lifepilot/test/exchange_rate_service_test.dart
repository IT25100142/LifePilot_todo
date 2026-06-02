import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifepilot/core/models/life_pilot_currency.dart';
import 'package:lifepilot/core/services/exchange_rate_service.dart';
import 'package:lifepilot/core/services/exchange_rate_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExchangeRateService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default rates when cache is empty', () async {
      final service = ExchangeRateService();
      await service.init();

      expect(service.rates[LifePilotCurrency.usd], 1.0);
      expect(service.rates[LifePilotCurrency.lkr], 300.0);
      expect(service.rates[LifePilotCurrency.eur], 0.92);
      expect(service.rates[LifePilotCurrency.gbp], 0.79);
      expect(service.lastSyncTime, isNull);
    });

    test('Loads cached rates when cache is present', () async {
      final payload = {'USD': 1.0, 'LKR': 320.0, 'EUR': 0.95, 'GBP': 0.81};
      final timestamp = DateTime(2026, 5, 28).toIso8601String();

      SharedPreferences.setMockInitialValues({
        'exchange_rates_payload': jsonEncode(payload),
        'exchange_rates_timestamp': timestamp,
      });

      final service = ExchangeRateService();
      await service.init();

      expect(service.rates[LifePilotCurrency.lkr], 320.0);
      expect(service.rates[LifePilotCurrency.eur], 0.95);
      expect(service.lastSyncTime, DateTime(2026, 5, 28));
    });

    test('Conversion logic math is correct', () {
      final service = ExchangeRateService();

      // USD to EUR
      final usdToEur = service.convert(
        amount: 100.0,
        from: LifePilotCurrency.usd,
        to: LifePilotCurrency.eur,
      );
      expect(usdToEur, closeTo(92.0, 0.001));

      // EUR to USD
      final eurToUsd = service.convert(
        amount: 92.0,
        from: LifePilotCurrency.eur,
        to: LifePilotCurrency.usd,
      );
      expect(eurToUsd, closeTo(100.0, 0.001));

      // EUR to LKR (1 EUR = 1 * (300 / 0.92) LKR = 326.0869)
      final eurToLkr = service.convert(
        amount: 1.0,
        from: LifePilotCurrency.eur,
        to: LifePilotCurrency.lkr,
      );
      expect(eurToLkr, closeTo(326.0869, 0.001));
    });

    test('syncRates handles success state and updates cache', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'result': 'success',
            'base_code': 'USD',
            'rates': {'USD': 1.0, 'LKR': 310.0, 'EUR': 0.93, 'GBP': 0.80},
          }),
          200,
        );
      });

      final service = ExchangeRateService(client: client);
      await service.init();

      final success = await service.syncRates();
      expect(success, isTrue);
      expect(service.rates[LifePilotCurrency.lkr], 310.0);
      expect(service.rates[LifePilotCurrency.eur], 0.93);
      expect(service.lastSyncTime, isNotNull);
    });

    test(
      'syncRates handles non-200 state gracefully and uses fallback cache',
      () async {
        final client = MockClient((request) async {
          return http.Response('Error', 500);
        });

        final service = ExchangeRateService(client: client);
        await service.init();

        final success = await service.syncRates();
        expect(success, isFalse);
        // Fallback is default rates
        expect(service.rates[LifePilotCurrency.lkr], 300.0);
        expect(service.lastSyncTime, isNull);
      },
    );
  });

  group('exchangeRateProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Provider exposes state and syncs successfully', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'result': 'success',
            'base_code': 'USD',
            'rates': {'USD': 1.0, 'LKR': 305.0, 'EUR': 0.91, 'GBP': 0.78},
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          exchangeRateServiceProvider.overrideWithValue(
            ExchangeRateService(client: client),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initial state is syncing
      expect(
        container.read(exchangeRateProvider).status,
        ExchangeRateSyncStatus.syncing,
      );

      // Wait for notifier initialization to complete sync
      await container.read(exchangeRateProvider.notifier).sync();

      final state = container.read(exchangeRateProvider);
      expect(state.status, ExchangeRateSyncStatus.synced);
      expect(state.rates[LifePilotCurrency.lkr], 305.0);
      expect(state.rates[LifePilotCurrency.eur], 0.91);

      final converted = state.convert(
        amount: 100.0,
        from: LifePilotCurrency.usd,
        to: LifePilotCurrency.lkr,
      );
      expect(converted, 30500.0);
    });

    test('Provider handles offline error fallback state', () async {
      final client = MockClient((request) async {
        return http.Response('Network offline', 503);
      });

      final container = ProviderContainer(
        overrides: [
          exchangeRateServiceProvider.overrideWithValue(
            ExchangeRateService(client: client),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Trigger sync and wait
      await container.read(exchangeRateProvider.notifier).sync();

      final state = container.read(exchangeRateProvider);
      expect(state.status, ExchangeRateSyncStatus.offlineErrorFallback);
      // Fallback is default rates
      expect(state.rates[LifePilotCurrency.lkr], 300.0);
    });
  });
}
