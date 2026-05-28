import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/services/notification_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import 'todo_providers.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pendingQuickActionProvider, (_, action) {
      if (action == QuickAction.task) {
        ref.read(pendingQuickActionProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTaskForm(context, ref);
        });
      }
    });

    final tasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        actions: [
          IconButton(
            tooltip: 'Add task',
            onPressed: () => showTaskForm(context, ref),
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _TaskControls(),
          const SizedBox(height: 16),
          tasks.when(
            loading: () => const SizedBox(height: 300, child: LoadingState()),
            error: (error, _) => ErrorState(error: error),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.checklist,
                  title: 'No matching tasks',
                  message: 'Add a task or adjust filters to see more.',
                  action: FilledButton.icon(
                    onPressed: () => showTaskForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add task'),
                  ),
                );
              }
              return Wrap(
                runSpacing: 10,
                children: [for (final task in items) _TaskTile(task: task)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Plan work',
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search tasks, tags, notes',
            ),
            onChanged: (value) =>
                ref.read(taskSearchProvider.notifier).state = value,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TaskFilter>(
                  initialValue: ref.watch(taskFilterProvider),
                  decoration: const InputDecoration(labelText: 'Filter'),
                  items: [
                    for (final filter in TaskFilter.values)
                      DropdownMenuItem(value: filter, child: Text(filter.name)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(taskFilterProvider.notifier).state = value;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TaskSort>(
                  initialValue: ref.watch(taskSortProvider),
                  decoration: const InputDecoration(labelText: 'Sort'),
                  items: [
                    for (final sort in TaskSort.values)
                      DropdownMenuItem(value: sort, child: Text(sort.name)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(taskSortProvider.notifier).state = value;
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final database = ref.watch(appDatabaseProvider);
    final overdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return GlassPanel(
      radius: 24,
      padding: EdgeInsets.zero,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.48,
      child: ListTile(
        minVerticalPadding: 14,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) async {
            await ref.read(toggleTaskCompletionProvider)(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(
                label: task.priority,
                color: switch (task.priority) {
                  'high' => theme.colorScheme.error,
                  'medium' => theme.colorScheme.tertiary,
                  _ => theme.colorScheme.primary,
                },
              ),
              _Chip(
                label: shortDate(task.dueDate),
                color: overdue
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
              ),
              if (task.tags.isNotEmpty)
                _Chip(label: task.tags, color: theme.colorScheme.outline),
              if (task.recurrencePattern != null && task.recurrencePattern != 'none')
                _Chip(
                  label: switch (task.recurrencePattern) {
                    'daily' => 'Daily',
                    'weekly' => 'Weekly',
                    'monthly' => 'Monthly',
                    _ => '',
                  },
                  color: const Color(0xFF286C63),
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              showTaskForm(context, ref, task: task);
            } else if (value == 'delete') {
              await ref
                  .read(notificationServiceProvider)
                  .cancel(taskReminderId(task.id));
              await database.deleteTask(task.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      visualDensity: VisualDensity.compact,
    );
  }
}

Future<void> showTaskForm(BuildContext context, WidgetRef ref, {Task? task}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.zero,
      child: _TaskForm(task: task),
    ),
  );
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({this.task});

  final Task? task;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  late String _priority;
  late String _recurrencePattern;
  DateTime? _dueDate;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _tags = TextEditingController(text: task?.tags ?? '');
    _priority = task?.priority ?? 'medium';
    _recurrencePattern = task?.recurrencePattern ?? 'none';
    _dueDate = task?.dueDate;
    _reminderAt = task?.reminderAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
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
              widget.task == null ? 'Add task' : 'Edit task',
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
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Categories or tags',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'medium'),
            ),
            const SizedBox(height: 16),
            Text(
              'Repeat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final pattern in ['none', 'daily', 'weekly', 'monthly'])
                  ChoiceChip(
                    label: Text(
                      switch (pattern) {
                        'none' => 'None',
                        'daily' => 'Daily',
                        'weekly' => 'Weekly',
                        'monthly' => 'Monthly',
                        _ => 'None',
                      },
                    ),
                    selected: _recurrencePattern == pattern,
                    selectedColor: const Color(0xFF286C63).withOpacity(0.24),
                    checkmarkColor: const Color(0xFF286C63),
                    labelStyle: TextStyle(
                      color: _recurrencePattern == pattern
                          ? const Color(0xFF286C63)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: _recurrencePattern == pattern
                          ? FontWeight.bold
                          : null,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _recurrencePattern = pattern);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DateTimeButtons(
              dueDate: _dueDate,
              reminderAt: _reminderAt,
              onPickDue: _pickDueDate,
              onClearDue: () => setState(() => _dueDate = null),
              onPickReminder: _pickReminder,
              onClearReminder: () => setState(() => _reminderAt = null),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
    );
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _pickReminder() async {
    final base = _dueDate ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? base),
    );
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? base.hour,
        time?.minute ?? base.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final database = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final existing = widget.task;
    final entry = TasksCompanion.insert(
      id: existing == null ? const Value.absent() : Value(existing.id),
      title: _title.text.trim(),
      description: Value(_description.text.trim()),
      dueDate: Value(_dueDate),
      reminderAt: Value(_reminderAt),
      priority: Value(_priority),
      tags: Value(_tags.text.trim()),
      isCompleted: Value(existing?.isCompleted ?? false),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
      recurrencePattern: Value(_recurrencePattern == 'none' ? null : _recurrencePattern),
      recurrenceParentId: Value(existing?.recurrenceParentId),
    );
    final savedId = await database.saveTask(entry);
    final id = existing?.id ?? savedId;
    final notification = ref.read(notificationServiceProvider);
    await notification.cancel(taskReminderId(id));
    if (_reminderAt != null) {
      await notification.schedule(
        id: taskReminderId(id),
        title: 'Task reminder',
        body: _title.text.trim(),
        when: _reminderAt!,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _DateTimeButtons extends StatelessWidget {
  const _DateTimeButtons({
    required this.dueDate,
    required this.reminderAt,
    required this.onPickDue,
    required this.onClearDue,
    required this.onPickReminder,
    required this.onClearReminder,
  });

  final DateTime? dueDate;
  final DateTime? reminderAt;
  final VoidCallback onPickDue;
  final VoidCallback onClearDue;
  final VoidCallback onPickReminder;
  final VoidCallback onClearReminder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InputChip(
          avatar: const Icon(Icons.today, size: 18),
          label: Text(
            dueDate == null
                ? 'Set due date'
                : '${shortDate(dueDate)} ${timeLabel(dueDate)}',
          ),
          onPressed: onPickDue,
          onDeleted: dueDate == null ? null : onClearDue,
        ),
        InputChip(
          avatar: const Icon(Icons.notifications_outlined, size: 18),
          label: Text(
            reminderAt == null
                ? 'Set reminder'
                : '${shortDate(reminderAt)} ${timeLabel(reminderAt)}',
          ),
          onPressed: onPickReminder,
          onDeleted: reminderAt == null ? null : onClearReminder,
        ),
      ],
    );
  }
}
