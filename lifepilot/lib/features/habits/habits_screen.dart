import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import 'habit_providers.dart';
import 'widgets/habit_heatmap.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(habitLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits & Rituals'),
        actions: [
          IconButton(
            tooltip: 'Add habit',
            onPressed: () => showHabitForm(context, ref),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: LiquidBackground(
        child: habitsAsync.when(
          loading: () => const Center(child: LoadingState()),
          error: (error, _) => ErrorState(error: error),
          data: (habits) {
            if (habits.isEmpty) {
              return EmptyState(
                icon: Icons.repeat_on_rounded,
                title: 'Design your rituals',
                message:
                    'Begin tracking your daily consistency matrix. Tap + to start.',
                action: FilledButton.icon(
                  onPressed: () => showHabitForm(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Create habit'),
                ),
              );
            }

            return logsAsync.when(
              loading: () => const Center(child: LoadingState()),
              error: (error, _) => ErrorState(error: error),
              data: (logs) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final habitLogs = logs
                        .where((l) => l.habitId == habit.id)
                        .toList();
                    final completedDates = habitLogs
                        .where((l) => l.isCompleted)
                        .map(
                          (l) =>
                              '${l.date.year}-${l.date.month.toString().padLeft(2, '0')}-${l.date.day.toString().padLeft(2, '0')}',
                        )
                        .toSet();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AnimatedGlassItem(
                        delay: Duration(milliseconds: index * 60),
                        child: _HabitCard(
                          habit: habit,
                          completedDates: completedDates,
                          ref: ref,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.completedDates,
    required this.ref,
  });

  final Habit habit;
  final Set<String> completedDates;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Streaks calculation helper
    int currentStreak = 0;
    DateTime d = startOfDay(DateTime.now());
    while (completedDates.contains(
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    )) {
      currentStreak++;
      d = d.subtract(const Duration(days: 1));
    }

    return LifePilotGleam(
      gleamId: 'habit_${habit.id}',
      radius: 20,
      child: LifePilotGlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Habit?'),
                          content: const Text(
                            'Deleting this habit will permanently erase all associated completion logs.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(habitActionsProvider)
                            .deleteHabit(habit.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (habit.categoryTag.isNotEmpty)
                  _HabitCategoryBadge(tag: habit.categoryTag)
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak day streak',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            LifePilotHabitHeatmap(
              completedDates: completedDates,
              onDateTapped: (date, isCompleted) {
                if (!isCompleted) {
                  LifePilotGleamRegistry.trigger('habit_${habit.id}');
                }
                ref
                    .read(habitActionsProvider)
                    .toggleHabitLog(habit.id, date, isCompleted);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCategoryBadge extends StatelessWidget {
  const _HabitCategoryBadge({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cleaned = tag.trim().toLowerCase();

    Color tintColor;
    switch (cleaned) {
      case 'daily routine':
      case 'routine':
        tintColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        break;
      case 'health & fitness':
      case 'fitness':
      case 'health':
        tintColor = const Color(0xFFE0516F);
        break;
      case 'mind & soul':
      case 'mindfulness':
        tintColor = dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
        break;
      case 'work & focus':
      case 'work':
      case 'focus':
        tintColor = theme.colorScheme.primary;
        break;
      case 'learning':
      case 'study':
        tintColor = const Color(0xFF286C63);
        break;
      default:
        tintColor = theme.colorScheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tintColor.withValues(alpha: 0.24),
          width: 1.0,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tintColor.withValues(alpha: dark ? 0.95 : 0.85),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

Future<void> showHabitForm(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.zero,
      child: const _HabitForm(),
    ),
  );
}

class _HabitForm extends ConsumerStatefulWidget {
  const _HabitForm();

  @override
  ConsumerState<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends ConsumerState<_HabitForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Daily Routine';

  final List<String> _categories = [
    'Daily Routine',
    'Health & Fitness',
    'Mind & Soul',
    'Work & Focus',
    'Learning',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'New Ritual & Habit',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Ritual Title',
                hintText: 'e.g., Morning Meditation',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description / Purpose',
                hintText: 'e.g., Clear mind, focus on breathing for 10 min',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text(
              'Category Tag',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in _categories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await ref
                          .read(habitActionsProvider)
                          .addHabit(
                            title: _titleController.text.trim(),
                            description: _descriptionController.text.trim(),
                            categoryTag: _selectedCategory,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save Habit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
