import 'package:intl/intl.dart';

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime endOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}

DateTime startOfMonth(DateTime value) {
  return DateTime(value.year, value.month);
}

DateTime nextMonth(DateTime value) {
  return DateTime(value.year, value.month + 1);
}

String monthLabel(DateTime value) => DateFormat.yMMMM().format(value);

String shortDate(DateTime? value) {
  if (value == null) return 'No date';
  return DateFormat('MMM d').format(value);
}

String timeLabel(DateTime? value) {
  if (value == null) return '';
  return DateFormat.jm().format(value);
}
