import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_pilot_currency.dart';

class ExchangeRateService {
  ExchangeRateService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _ratesKey = 'exchange_rates_payload';
  static const String _timestampKey = 'exchange_rates_timestamp';
  static const String _url = 'https://open.er-api.com/v6/latest/USD';

  static const Map<LifePilotCurrency, double> defaultRates = {
    LifePilotCurrency.usd: 1.0,
    LifePilotCurrency.lkr: 300.0,
    LifePilotCurrency.eur: 0.92,
    LifePilotCurrency.gbp: 0.79,
  };

  Map<LifePilotCurrency, double> _cachedRates = Map.from(defaultRates);
  DateTime? _lastSyncTime;
  SharedPreferences? _prefs;

  Map<LifePilotCurrency, double> get rates => _cachedRates;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      loadFromCache();
    } catch (_) {
      // Handle SharedPreferences init failure (e.g. in tests/unsupported environments)
    }
  }

  void loadFromCache() {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final jsonStr = prefs.getString(_ratesKey);
      final timestampStr = prefs.getString(_timestampKey);
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final Map<LifePilotCurrency, double> newRates = {};
        for (final currency in LifePilotCurrency.values) {
          final val = decoded[currency.code];
          if (val is num) {
            newRates[currency] = val.toDouble();
          } else {
            newRates[currency] = defaultRates[currency]!;
          }
        }
        _cachedRates = newRates;
      }
      if (timestampStr != null) {
        _lastSyncTime = DateTime.tryParse(timestampStr);
      }
    } catch (_) {
      // Ignore cache load errors and keep existing/default rates
    }
  }

  Future<bool> syncRates() async {
    try {
      final response = await _client
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final ratesMap = decoded['rates'] as Map<String, dynamic>?;
        if (ratesMap != null) {
          final Map<LifePilotCurrency, double> newRates = {};
          final Map<String, double> cachePayload = {};

          for (final currency in LifePilotCurrency.values) {
            final rate = ratesMap[currency.code];
            if (rate is num) {
              newRates[currency] = rate.toDouble();
              cachePayload[currency.code] = rate.toDouble();
            } else {
              newRates[currency] =
                  _cachedRates[currency] ?? defaultRates[currency]!;
              cachePayload[currency.code] = newRates[currency]!;
            }
          }

          _cachedRates = newRates;
          _lastSyncTime = DateTime.now();

          final prefs = _prefs;
          if (prefs != null) {
            await prefs.setString(_ratesKey, jsonEncode(cachePayload));
            await prefs.setString(
              _timestampKey,
              _lastSyncTime!.toIso8601String(),
            );
          }
          return true;
        }
      }
    } catch (_) {
      // Catch network errors, timeouts, status != 200, format exceptions, etc.
    }
    return false;
  }

  double convert({
    required double amount,
    required LifePilotCurrency from,
    required LifePilotCurrency to,
  }) {
    final rateFrom = _cachedRates[from] ?? defaultRates[from]!;
    final rateTo = _cachedRates[to] ?? defaultRates[to]!;
    if (rateFrom == 0.0) return 0.0;
    return amount * (rateTo / rateFrom);
  }
}
