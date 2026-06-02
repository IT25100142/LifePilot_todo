import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/life_pilot_currency.dart';
import 'exchange_rate_service.dart';

enum ExchangeRateSyncStatus { syncing, synced, offlineErrorFallback }

class ExchangeRateState {
  final ExchangeRateSyncStatus status;
  final Map<LifePilotCurrency, double> rates;
  final DateTime? lastSyncTime;

  const ExchangeRateState({
    required this.status,
    required this.rates,
    this.lastSyncTime,
  });

  ExchangeRateState copyWith({
    ExchangeRateSyncStatus? status,
    Map<LifePilotCurrency, double>? rates,
    DateTime? lastSyncTime,
  }) {
    return ExchangeRateState(
      status: status ?? this.status,
      rates: rates ?? this.rates,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  double convert({
    required double amount,
    required LifePilotCurrency from,
    required LifePilotCurrency to,
  }) {
    final rateFrom = rates[from] ?? 1.0;
    final rateTo = rates[to] ?? 1.0;
    if (rateFrom == 0.0) return 0.0;
    return amount * (rateTo / rateFrom);
  }
}

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final exchangeRateProvider =
    StateNotifierProvider<ExchangeRateNotifier, ExchangeRateState>((ref) {
      final service = ref.watch(exchangeRateServiceProvider);
      return ExchangeRateNotifier(service);
    });

class ExchangeRateNotifier extends StateNotifier<ExchangeRateState> {
  ExchangeRateNotifier(this._service)
    : super(
        const ExchangeRateState(
          status: ExchangeRateSyncStatus.syncing,
          rates: ExchangeRateService.defaultRates,
        ),
      ) {
    _init();
  }

  final ExchangeRateService _service;

  Future<void> _init() async {
    await _service.init();
    if (!mounted) return;
    state = ExchangeRateState(
      status: ExchangeRateSyncStatus.syncing,
      rates: _service.rates,
      lastSyncTime: _service.lastSyncTime,
    );
    await sync();
  }

  Future<void> sync() async {
    if (!mounted) return;
    state = state.copyWith(status: ExchangeRateSyncStatus.syncing);
    final success = await _service.syncRates();
    if (!mounted) return;
    state = ExchangeRateState(
      status: success
          ? ExchangeRateSyncStatus.synced
          : ExchangeRateSyncStatus.offlineErrorFallback,
      rates: _service.rates,
      lastSyncTime: _service.lastSyncTime,
    );
  }

  Future<void> fetchRates() => sync();

  double convert({
    required double amount,
    required LifePilotCurrency from,
    required LifePilotCurrency to,
  }) {
    return _service.convert(amount: amount, from: from, to: to);
  }
}
