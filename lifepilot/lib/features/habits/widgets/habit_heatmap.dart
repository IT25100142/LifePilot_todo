import 'package:flutter/material.dart';

import '../../../core/utils/date_helpers.dart';

class LifePilotHabitHeatmap extends StatelessWidget {
  const LifePilotHabitHeatmap({
    super.key,
    required this.completedDates,
    required this.onDateTapped,
  });

  final Set<String> completedDates;
  final Function(DateTime date, bool isCompleted) onDateTapped;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateStreak(DateTime date) {
    int streak = 0;
    DateTime d = startOfDay(date);
    while (completedDates.contains(_formatDate(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final today = startOfDay(DateTime.now());
    final mondayOfCurrentWeek = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final gridStartDate = mondayOfCurrentWeek.subtract(
      const Duration(days: 11 * 7),
    );

    final rowLabels = ['M', '', 'W', '', 'F', '', 'S'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Labels Column
        Column(
          children: [
            const SizedBox(height: 2),
            for (var i = 0; i < 7; i++)
              Container(
                height: 20,
                width: 14,
                alignment: Alignment.centerLeft,
                child: Text(
                  rowLabels[i],
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // Heatmap Grid Scroll View / Container
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int col = 0; col < 12; col++) ...[
                  if (col > 0) const SizedBox(width: 4),
                  Column(
                    children: [
                      for (int row = 0; row < 7; row++) ...[
                        if (row > 0) const SizedBox(height: 4),
                        _buildCell(
                          context,
                          gridStartDate.add(Duration(days: col * 7 + row)),
                          today,
                          theme,
                          isDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime date,
    DateTime today,
    ThemeData theme,
    bool isDark,
  ) {
    final dateStr = _formatDate(date);
    final isCompleted = completedDates.contains(dateStr);
    final isFuture = date.isAfter(today);

    Color color;
    BoxBorder? border;
    List<BoxShadow>? shadow;
    Gradient? gradient;

    if (isFuture) {
      color = theme.colorScheme.onSurface.withValues(alpha: 0.02);
    } else if (!isCompleted) {
      color = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    } else {
      final streak = _calculateStreak(date);
      // Premium Palette based on completion consistency streaks
      if (streak >= 6) {
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        );
        color = theme.colorScheme.primary;
        shadow = [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isDark ? 0.35 : 0.25,
            ),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ];
      } else if (streak >= 3) {
        color = theme.colorScheme.primary.withValues(alpha: 0.85);
        shadow = [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ];
      } else {
        color = theme.colorScheme.primary.withValues(alpha: 0.55);
      }
    }

    return GestureDetector(
      onTap: isFuture
          ? null
          : () {
              onDateTapped(date, !isCompleted);
            },
      child: Tooltip(
        message:
            '${shortDate(date)}: ${isCompleted ? 'Completed' : 'Not completed'}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(5),
            border: border,
            boxShadow: shadow,
          ),
        ),
      ),
    );
  }
}
