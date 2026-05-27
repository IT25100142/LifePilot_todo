import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../calendar/calendar_providers.dart';
import '../finance/finance_providers.dart';
import '../settings/settings_providers.dart';
import '../todo/todo_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedDataProvider);
    final currency =
        ref.watch(settingsControllerProvider).valueOrNull?.currency ?? 'LKR';
    final tasks = ref.watch(tasksProvider);
    final events = ref.watch(eventsProvider);
    final entries = ref.watch(financeEntriesProvider);

    return seed.when(
      loading: () => const LoadingState(),
      error: (error, _) => ErrorState(error: error),
      data: (_) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('LifePilot'),
                actions: [
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroHeader(currency: currency, entries: entries),
                    const SizedBox(height: 16),
                    _QuickActions(ref: ref),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final children = [
                          _TodayTasks(tasks: tasks),
                          _UpcomingEvents(events: events),
                        ];
                        if (!wide) {
                          return Column(
                            children: [
                              children[0],
                              const SizedBox(height: 16),
                              children[1],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: children[0]),
                            const SizedBox(width: 16),
                            Expanded(child: children[1]),
                          ],
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.currency, required this.entries});

  final String currency;
  final AsyncValue<List<FinanceEntry>> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = startOfMonth(DateTime.now());
    final summary = entries.valueOrNull == null
        ? null
        : buildFinanceSummary(
            entries.value!
                .where(
                  (entry) =>
                      entry.date.year == month.year &&
                      entry.date.month == month.month,
                )
                .toList(),
          );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today at a glance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monthLabel(DateTime.now()),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill('Income', money(summary?.income ?? 0, currency)),
              _MetricPill('Expenses', money(summary?.expenses ?? 0, currency)),
              _MetricPill('Balance', money(summary?.balance ?? 0, currency)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onPrimary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Quick actions',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () {
              ref.read(pendingQuickActionProvider.notifier).state =
                  QuickAction.task;
              context.go('/todo');
            },
            icon: const Icon(Icons.add_task),
            label: const Text('Add Task'),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(pendingQuickActionProvider.notifier).state =
                  QuickAction.event;
              context.go('/calendar');
            },
            icon: const Icon(Icons.event_available),
            label: const Text('Add Event'),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(pendingQuickActionProvider.notifier).state =
                  QuickAction.transaction;
              context.go('/finance');
            },
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.tasks});

  final AsyncValue<List<Task>> tasks;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "Today's tasks",
      action: TextButton(
        onPressed: () => context.go('/todo'),
        child: const Text('View all'),
      ),
      child: tasks.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Text(error.toString()),
        data: (items) {
          final today = DateTime.now();
          final todaysTasks = items
              .where(
                (task) =>
                    task.dueDate != null && isSameDate(task.dueDate!, today),
              )
              .take(4)
              .toList();
          if (todaysTasks.isEmpty) {
            return const Text('No tasks due today. Your runway is clear.');
          }
          return Column(
            children: [
              for (final task in todaysTasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(task.title),
                  subtitle: Text('${task.priority} priority'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents({required this.events});

  final AsyncValue<List<CalendarEvent>> events;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Upcoming events',
      action: TextButton(
        onPressed: () => context.go('/calendar'),
        child: const Text('Calendar'),
      ),
      child: events.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Text(error.toString()),
        data: (items) {
          final now = DateTime.now();
          final upcoming = items
              .where((event) => event.startTime.isAfter(now))
              .take(4)
              .toList();
          if (upcoming.isEmpty) {
            return const Text('No upcoming events on the calendar.');
          }
          return Column(
            children: [
              for (final event in upcoming)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text(event.title),
                  subtitle: Text(
                    '${shortDate(event.date)} ${timeLabel(event.startTime)}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
