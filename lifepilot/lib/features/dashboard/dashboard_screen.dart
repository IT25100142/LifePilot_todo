import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../calendar/calendar_providers.dart';
import '../finance/finance_providers.dart';
import '../settings/settings_providers.dart';
import '../todo/todo_providers.dart';
import 'search_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(activeCurrencyCodeProvider);
    final tasks = ref.watch(tasksProvider);
    final events = ref.watch(eventsProvider);
    final entries = ref.watch(financeEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackdrop()),
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
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
                    const _SearchBar(),
                    const SizedBox(height: 16),
                    if (ref.watch(searchQueryProvider).trim().isEmpty) ...[
                      AnimatedGlassItem(
                        child: _HeroHeader(
                          currency: currency,
                          entries: entries,
                        ),
                      ),
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
                    ] else ...[
                      _SearchResultsView(currency: currency),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
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

    return LifePilotGlassCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIcon(
                icon: Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Today at a glance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${monthLabel(DateTime.now())} forecast across tasks, calendar, and money.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(
                label: 'Income',
                value: money(summary?.income ?? 0, currency),
                icon: Icons.trending_up_rounded,
              ),
              _MetricPill(
                label: 'Expenses',
                value: money(summary?.expenses ?? 0, currency),
                icon: Icons.trending_down_rounded,
              ),
              _MetricPill(
                label: 'Balance',
                value: money(summary?.balance ?? 0, currency),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LifePilotGlassCard(
      constraints: const BoxConstraints(minWidth: 160),
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
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

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    if (query != _controller.text) {
      _controller.text = query;
    }

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final inactiveCardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
            ]
          : [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.06),
            ],
    );

    final inactiveBorderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.04),
            ]
          : [
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0.08),
            ],
    );

    final activeCardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.primary.withValues(alpha: 0.03),
            ]
          : [
              theme.colorScheme.primary.withValues(alpha: 0.22),
              theme.colorScheme.primary.withValues(alpha: 0.08),
            ],
    );

    final activeBorderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.70),
        theme.colorScheme.primary.withValues(alpha: 0.24),
      ],
    );

    final shadowColor = _isFocused
        ? theme.colorScheme.primary.withValues(alpha: dark ? 0.16 : 0.08)
        : (dark
              ? Colors.black.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.06));

    return LifePilotGlassCard(
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      cardGradient: _isFocused ? activeCardGradient : inactiveCardGradient,
      borderGradient: _isFocused
          ? activeBorderGradient
          : inactiveBorderGradient,
      shadowColor: shadowColor,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks, events, money...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(globalSearchResultsProvider);
    final theme = Theme.of(context);

    return resultsAsync.when(
      loading: () => const SizedBox(height: 200, child: LoadingState()),
      error: (error, _) => ErrorState(error: error),
      data: (results) {
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            message: 'Try searching for different keywords.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (results.tasks.isNotEmpty) ...[
              _ResultSectionHeader(
                title: 'Tasks (${results.tasks.length})',
                icon: Icons.checklist,
              ),
              const SizedBox(height: 8),
              for (final task in results.tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    radius: 20,
                    padding: EdgeInsets.zero,
                    opacity: theme.brightness == Brightness.dark ? 0.14 : 0.48,
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) async {
                          await ref.read(toggleTaskCompletionProvider)(task);
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: task.description.isNotEmpty
                          ? Text(task.description)
                          : null,
                      trailing: Text(
                        _priorityLabel(task.priority),
                        style: TextStyle(
                          color: switch (task.priority) {
                            'high' => theme.colorScheme.error,
                            'medium' => theme.colorScheme.tertiary,
                            _ => theme.colorScheme.primary,
                          },
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (results.events.isNotEmpty) ...[
              _ResultSectionHeader(
                title: 'Events (${results.events.length})',
                icon: Icons.event,
              ),
              const SizedBox(height: 8),
              for (final event in results.events)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    radius: 20,
                    padding: EdgeInsets.zero,
                    opacity: theme.brightness == Brightness.dark ? 0.14 : 0.48,
                    child: ListTile(
                      leading: const GlassIcon(
                        icon: Icons.calendar_today_outlined,
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${shortDate(event.date)} at ${timeLabel(event.startTime)}',
                      ),
                      onTap: () => context.go('/calendar'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (results.transactions.isNotEmpty) ...[
              _ResultSectionHeader(
                title: 'Transactions (${results.transactions.length})',
                icon: Icons.payments,
              ),
              const SizedBox(height: 8),
              for (final tx in results.transactions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    radius: 20,
                    padding: EdgeInsets.zero,
                    opacity: theme.brightness == Brightness.dark ? 0.14 : 0.48,
                    child: ListTile(
                      leading: GlassIcon(
                        icon: tx.type == 'income'
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: tx.type == 'income'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      title: Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${tx.category} • ${shortDate(tx.date)}'),
                      trailing: Text(
                        money(
                          tx.amount,
                          tx.currency.isEmpty ? currency : tx.currency,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => context.go('/finance'),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ResultSectionHeader extends StatelessWidget {
  const _ResultSectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

String _priorityLabel(String priority) {
  if (priority.isEmpty) return '';
  return '${priority.substring(0, 1).toUpperCase()}${priority.substring(1)}';
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGlow = const Color(
      0xFFD6BD92,
    ).withValues(alpha: isDark ? 0.12 : 0.10);
    final secondaryGlow = const Color(
      0xFFC8A97A,
    ).withValues(alpha: isDark ? 0.10 : 0.08);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF151316) : const Color(0xFFF7F3EC),
          ),
        ),
        Positioned(
          top: -120,
          left: -120,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryGlow, primaryGlow.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -150,
          width: 480,
          height: 480,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [secondaryGlow, secondaryGlow.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
