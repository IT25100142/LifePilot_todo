import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/services/notification_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import 'calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pendingQuickActionProvider, (_, action) {
      if (action == QuickAction.event) {
        ref.read(pendingQuickActionProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showEventForm(context, ref);
        });
      }
    });

    final events = ref.watch(eventsProvider);
    final tasks = ref.watch(selectedDayTasksProvider);
    final dayEvents = ref.watch(selectedDayEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Add event',
            onPressed: () => showEventForm(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEventForm(context, ref),
        icon: const Icon(Icons.event_available),
        label: const Text('Event'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _MonthCard(events: events),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final children = [
                _DailySchedule(events: dayEvents),
                _LinkedTasks(tasks: tasks),
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
        ],
      ),
    );
  }
}

class _MonthCard extends ConsumerStatefulWidget {
  const _MonthCard({required this.events});

  final AsyncValue<List<CalendarEvent>> events;

  @override
  ConsumerState<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends ConsumerState<_MonthCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleMonth = ref.watch(visibleCalendarMonthProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);

    // Week strip logic: find the Monday of the selected day's week
    final monday = selectedDay.subtract(
      Duration(days: selectedDay.weekday - 1),
    );
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    // Month grid logic
    final firstWeekday = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    ).weekday;
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final totalCells = ((firstWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: _isExpanded ? 260.0 : 130.0),
        child: SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          title: _isExpanded
              ? monthLabel(visibleMonth)
              : 'Week of ${shortDate(selectedDay)}',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Previous month',
                  onPressed: () =>
                      ref.read(visibleCalendarMonthProvider.notifier).state =
                          DateTime(visibleMonth.year, visibleMonth.month - 1),
                  icon: const Icon(Icons.chevron_left, size: 20),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Next month',
                  onPressed: () =>
                      ref.read(visibleCalendarMonthProvider.notifier).state =
                          DateTime(visibleMonth.year, visibleMonth.month + 1),
                  icon: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _isExpanded ? 'Show week' : 'Show month',
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_isExpanded)
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      final dayNumber = index - firstWeekday + 2;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final date = DateTime(
                        visibleMonth.year,
                        visibleMonth.month,
                        dayNumber,
                      );
                      final isSelected = isSameDate(date, selectedDay);
                      final hasEvent =
                          widget.events.valueOrNull?.any(
                            (e) => isSameDate(e.date, date),
                          ) ??
                          false;

                      return _CalendarDay(
                        day: dayNumber,
                        selected: isSelected,
                        hasEvent: hasEvent,
                        onTap: () {
                          ref.read(selectedCalendarDayProvider.notifier).state =
                              date;
                        },
                      );
                    },
                  ),
                )
              else
                Row(
                  children: [
                    for (final date in weekDays)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: _CalendarDay(
                              day: date.day,
                              selected: isSameDate(date, selectedDay),
                              hasEvent:
                                  widget.events.valueOrNull?.any(
                                    (e) => isSameDate(e.date, date),
                                  ) ??
                                  false,
                              onTap: () {
                                ref
                                        .read(
                                          selectedCalendarDayProvider.notifier,
                                        )
                                        .state =
                                    date;
                                if (date.month != visibleMonth.month) {
                                  ref
                                      .read(
                                        visibleCalendarMonthProvider.notifier,
                                      )
                                      .state = DateTime(
                                    date.year,
                                    date.month,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final selectedBackgroundColor = theme.colorScheme.primary.withValues(
      alpha: 0.38,
    );
    final selectedBorderColor = theme.colorScheme.primary.withValues(
      alpha: 0.72,
    );

    final cardGradient = selected
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              selectedBackgroundColor,
              theme.colorScheme.primary.withValues(alpha: 0.12),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.01),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
          );

    final borderGradient = selected
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              selectedBorderColor,
              theme.colorScheme.primary.withValues(alpha: 0.28),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.04),
            ],
          );

    final shadowColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: LifePilotGlassCard(
        radius: 12,
        padding: EdgeInsets.zero,
        cardGradient: cardGradient,
        borderGradient: borderGradient,
        shadowColor: shadowColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: hasEvent ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySchedule extends ConsumerWidget {
  const _DailySchedule({required this.events});

  final AsyncValue<List<CalendarEvent>> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCalendarDayProvider);
    return SectionCard(
      title: 'Daily schedule',
      subtitle: '${shortDate(selected)} ${selected.year}',
      child: events.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (items) {
          if (items.isEmpty) {
            return const Text('No events scheduled for this day.');
          }
          return Column(
            children: [for (final event in items) _EventTile(event: event)],
          );
        },
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final database = ref.watch(appDatabaseProvider);

    // Champagne edge highlight gradient (primary/tertiary colors in theme)
    final champagneBorder = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.36),
        theme.colorScheme.primary.withValues(alpha: 0.08),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LifePilotGlassCard(
        radius: 20,
        padding: EdgeInsets.zero,
        borderGradient: champagneBorder,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: const GlassIcon(icon: Icons.schedule),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${timeLabel(event.startTime)} - ${timeLabel(event.endTime)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                showEventForm(context, ref, event: event);
              } else if (value == 'delete') {
                await ref
                    .read(notificationServiceProvider)
                    .cancel(eventReminderId(event.id));
                await database.deleteEvent(event.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedTasks extends StatelessWidget {
  const _LinkedTasks({required this.tasks});

  final AsyncValue<List<Task>> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Tasks on this date',
      child: tasks.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (items) {
          if (items.isEmpty) return const Text('No dated tasks here.');
          return Column(
            children: [
              for (final task in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LifePilotGlassCard(
                    radius: 20,
                    padding: EdgeInsets.zero,
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.28),
                        theme.colorScheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      leading: Icon(
                        task.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: theme.colorScheme.primary,
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
                      subtitle: Text(
                        '${_toTitleCase(task.priority)} Priority',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _toTitleCase(String value) {
  if (value.isEmpty) return value;
  return '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
}

Future<void> showEventForm(
  BuildContext context,
  WidgetRef ref, {
  CalendarEvent? event,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.zero,
      child: _EventForm(event: event),
    ),
  );
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.event});

  final CalendarEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final now = DateTime.now();
    _title = TextEditingController(text: event?.title ?? '');
    _description = TextEditingController(text: event?.description ?? '');
    _date = event?.date ?? DateTime(now.year, now.month, now.day);
    _start = TimeOfDay.fromDateTime(event?.startTime ?? now);
    _end = TimeOfDay.fromDateTime(
      event?.endTime ?? now.add(const Duration(hours: 1)),
    );
    _reminderAt = event?.reminderAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.event == null ? 'Add event' : 'Edit event',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                InputChip(
                  avatar: const Icon(Icons.today, size: 18),
                  label: Text('${shortDate(_date)} ${_date.year}'),
                  onPressed: _pickDate,
                ),
                InputChip(
                  avatar: const Icon(Icons.play_arrow, size: 18),
                  label: Text('Start ${_start.format(context)}'),
                  onPressed: _pickStart,
                ),
                InputChip(
                  avatar: const Icon(Icons.stop, size: 18),
                  label: Text('End ${_end.format(context)}'),
                  onPressed: _pickEnd,
                ),
                InputChip(
                  avatar: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text(
                    _reminderAt == null
                        ? 'Set reminder'
                        : '${shortDate(_reminderAt)} ${timeLabel(_reminderAt)}',
                  ),
                  onPressed: _pickReminder,
                  onDeleted: _reminderAt == null
                      ? null
                      : () => setState(() => _reminderAt = null),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save event'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  Future<void> _pickReminder() async {
    final start = _combine(_date, _start);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? start),
    );
    setState(() {
      _reminderAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? start.hour,
        pickedTime?.minute ?? start.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _combine(_date, _start);
    var end = _combine(_date, _end);
    if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));

    final database = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final existing = widget.event;
    final entry = CalendarEventsCompanion.insert(
      id: existing == null ? const Value.absent() : Value(existing.id),
      title: _title.text.trim(),
      description: Value(_description.text.trim()),
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: start,
      endTime: end,
      reminderAt: Value(_reminderAt),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );
    final savedId = await database.saveEvent(entry);
    final id = existing?.id ?? savedId;
    final notification = ref.read(notificationServiceProvider);
    await notification.cancel(eventReminderId(id));
    if (_reminderAt != null) {
      await notification.schedule(
        id: eventReminderId(id),
        title: 'Event reminder',
        body: _title.text.trim(),
        when: _reminderAt!,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
