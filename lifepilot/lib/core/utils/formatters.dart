import 'package:intl/intl.dart';

import '../models/life_pilot_currency.dart';

String money(num amount, String currency) {
  final selectedCurrency = currencyFromCode(currency);
  final formatter = NumberFormat.currency(
    name: selectedCurrency.code,
    symbol: '${selectedCurrency.symbol} ',
    decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
  );
  return formatter.format(amount);
}

String compactNumber(num value) {
  return NumberFormat.compact().format(value);
}
