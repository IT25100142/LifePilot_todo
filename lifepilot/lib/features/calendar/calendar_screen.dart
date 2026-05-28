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

    final isWide = MediaQuery.sizeOf(context).width >= 800;

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
      body: isWide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Fixed Calendar Dock
                  SizedBox(width: 380, child: _MonthCard(events: events)),
                  const SizedBox(width: 24),
                  // Right Column: Flexible Agenda Feed with independent scrolling
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 96),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final rightWide = constraints.maxWidth >= 600;
                          if (rightWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _DailySchedule(events: dayEvents),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _LinkedTasks(tasks: tasks)),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DailySchedule(events: dayEvents),
                                const SizedBox(height: 16),
                                _LinkedTasks(tasks: tasks),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _MonthCard(events: events),
                const SizedBox(height: 16),
                _DailySchedule(events: dayEvents),
                const SizedBox(height: 16),
                _LinkedTasks(tasks: tasks),
              ],
            ),
    );
  }
}

class _MonthCard extends ConsumerWidget {
  const _MonthCard({required this.events});

  final AsyncValue<List<CalendarEvent>> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visibleMonth = ref.watch(visibleCalendarMonthProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);

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

    const totalCells = 35;

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      title: monthLabel(visibleMonth),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
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
                  events.valueOrNull?.any((e) => isSameDate(e.date, date)) ??
                  false;

              return Center(
                child: _CalendarDay(
                  date: date,
                  day: dayNumber,
                  selected: isSelected,
                  hasEvent: hasEvent,
                  onTap: () {
                    ref.read(selectedCalendarDayProvider.notifier).state = date;
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatefulWidget {
  const _CalendarDay({
    required this.date,
    required this.day,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime date;
  final int day;
  final bool selected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  State<_CalendarDay> createState() => _CalendarDayState();
}

class _CalendarDayState extends State<_CalendarDay> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isToday = isSameDate(widget.date, DateTime.now());

    final goldColor = theme.colorScheme.primary;

    Widget cellChild = Center(
      child: Text(
        '${widget.day}',
        style: TextStyle(
          fontWeight: widget.selected || isToday
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 14,
          color: widget.selected
              ? theme.colorScheme.onPrimary
              : isToday
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(
                  alpha: _isHovered ? 0.9 : 0.3,
                ),
        ),
      ),
    );

    if (widget.hasEvent) {
      cellChild = Stack(
        alignment: Alignment.center,
        children: [
          cellChild,
          Positioned(
            bottom: 4,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: widget.selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    BoxDecoration decoration;
    if (widget.selected) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldColor.withValues(alpha: 0.85),
            goldColor.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: goldColor.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark
              ? const Color(0xFFE5DED2).withValues(alpha: 0.7)
              : const Color(0xFF8A847C).withValues(alpha: 0.6),
          width: 1.5,
        ),
        color: Colors.transparent,
      );
    } else {
      decoration = const BoxDecoration(color: Colors.transparent);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: decoration,
          child: cellChild,
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
