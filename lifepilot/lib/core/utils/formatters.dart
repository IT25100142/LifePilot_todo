import 'package:intl/intl.dart';

String money(num amount, String currency) {
  final formatter = NumberFormat.currency(
    name: currency,
    symbol: '$currency ',
    decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
  );
  return formatter.format(amount);
}

String compactNumber(num value) {
  return NumberFormat.compact().format(value);
}
