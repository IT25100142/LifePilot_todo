enum LifePilotCurrency { lkr, usd, eur, gbp }

extension LifePilotCurrencyX on LifePilotCurrency {
  String get code => switch (this) {
    LifePilotCurrency.lkr => 'LKR',
    LifePilotCurrency.usd => 'USD',
    LifePilotCurrency.eur => 'EUR',
    LifePilotCurrency.gbp => 'GBP',
  };

  String get symbol => switch (this) {
    LifePilotCurrency.lkr => 'Rs',
    LifePilotCurrency.usd => r'$',
    LifePilotCurrency.eur => '€',
    LifePilotCurrency.gbp => '£',
  };

  String get label => switch (this) {
    LifePilotCurrency.lkr => 'Sri Lankan Rupee',
    LifePilotCurrency.usd => 'US Dollar',
    LifePilotCurrency.eur => 'Euro',
    LifePilotCurrency.gbp => 'British Pound',
  };
}

LifePilotCurrency currencyFromCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  return switch (normalized) {
    'USD' => LifePilotCurrency.usd,
    'EUR' => LifePilotCurrency.eur,
    'GBP' => LifePilotCurrency.gbp,
    _ => LifePilotCurrency.lkr,
  };
}
