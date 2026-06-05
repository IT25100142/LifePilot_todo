import 'package:flutter/material.dart';

class MonthNavigation extends StatelessWidget {
  const MonthNavigation({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
    this.iconSize = 24,
    this.compact = false,
  });

  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: compact ? VisualDensity.compact : null,
          tooltip: 'Previous month',
          onPressed: () => onMonthChanged(
            DateTime(currentMonth.year, currentMonth.month - 1),
          ),
          icon: Icon(Icons.chevron_left, size: iconSize),
        ),
        IconButton(
          visualDensity: compact ? VisualDensity.compact : null,
          tooltip: 'Next month',
          onPressed: () => onMonthChanged(
            DateTime(currentMonth.year, currentMonth.month + 1),
          ),
          icon: Icon(Icons.chevron_right, size: iconSize),
        ),
      ],
    );
  }
}
