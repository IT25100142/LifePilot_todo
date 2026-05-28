import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../calendar/calendar_providers.dart';
import '../settings/settings_providers.dart';
import '../todo/todo_providers.dart';
import 'search_provider.dart';

// Import features for integration
import '../finance/finance_screen.dart';
import '../todo/todo_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(activeCurrencyCodeProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackdrop()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
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
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _SearchBar(),
                      const SizedBox(height: 24),
                      if (query.isNotEmpty)
                        _SearchResultsView(currency: currency)
                      else if (isWide) ...[
                        const _DashboardHeader(),
                        const SizedBox(height: 24),
                        const _DashboardWeekStrip(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Converted Analytics Window
                            const Expanded(
                              flex: 5,
                              child: LifePilotFinanceAnalytics(),
                            ),
                            const SizedBox(width: 24),
                            // Right Column: High-Priority Task Canvas
                            const Expanded(
                              flex: 6,
                              child: _DashboardPriorityTasks(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 96),
                      ] else ...[
                        const _DashboardHeader(),
                        const SizedBox(height: 24),
                        const _DashboardWeekStrip(),
                        const SizedBox(height: 16),
                        const LifePilotFinanceAnalytics(),
                        const SizedBox(height: 16),
                        const _DashboardPriorityTasks(),
                        const SizedBox(height: 96),
                      ],
                    ]),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'GOOD MORNING, SANKALPA';
    } else if (hour < 17) {
      greeting = 'GOOD AFTERNOON, SANKALPA';
    } else {
      greeting = 'GOOD EVENING, SANKALPA';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEM OPERATIONAL • SECURE FALLBACK SYNC',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardWeekStrip extends ConsumerWidget {
  const _DashboardWeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(eventsProvider);

    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return LifePilotGlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY RUNWAY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in weekDays)
                _buildDayCell(context, day, today, eventsAsync.valueOrNull),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime today,
    List<CalendarEvent>? events,
  ) {
    final theme = Theme.of(context);
    final isToday = isSameDate(day, today);
    final hasEvents = events?.any((e) => isSameDate(e.date, day)) ?? false;

    final label = switch (day.weekday) {
      1 => 'M',
      2 => 'T',
      3 => 'W',
      4 => 'T',
      5 => 'F',
      6 => 'S',
      7 => 'S',
      _ => '',
    };

    BoxDecoration decoration;
    if (isToday) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      );
    } else {
      decoration = const BoxDecoration(color: Colors.transparent);
    }

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            decoration: decoration,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
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

class _DashboardPriorityTasks extends ConsumerWidget {
  const _DashboardPriorityTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) =>
          SizedBox(height: 150, child: Center(child: Text('Error: $err'))),
      data: (items) {
        final highPriorityTasks = items
            .where((t) => t.priority == 'high' && !t.isCompleted)
            .toList();

        return SectionCard(
          title: 'Urgent Tasks',
          action: TextButton(
            onPressed: () => context.go('/todo'),
            child: const Text('View all'),
          ),
          child: highPriorityTasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('All clear! No urgent tasks pending.'),
                )
              : Column(
                  children: [
                    for (final task in highPriorityTasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskTile(task: task),
                      ),
                  ],
                ),
        );
      },
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
