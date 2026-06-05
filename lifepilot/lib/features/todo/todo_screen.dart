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
                  title: 'All caught up',
                  message:
                      'No tasks yet. Add your first task to start a focused day.',
                  action: FilledButton.icon(
                    onPressed: () => showTaskForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add task'),
                  ),
                );
              }
              return Wrap(
                runSpacing: 10,
                children: [for (final task in items) TaskTile(task: task)],
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

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskTile> createState() => TaskTileState();
}

class TaskTileState extends ConsumerState<TaskTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final database = ref.watch(appDatabaseProvider);
    final overdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    final subtasksAsync = ref.watch(subtasksProvider(task.id));
    final hasSubtasks = subtasksAsync.valueOrNull?.isNotEmpty ?? false;

    Gradient? borderGradient;
    Color? shadowColor;

    if (task.priority == 'high') {
      final crimsonColor = const Color(0xFFA36461);
      borderGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          crimsonColor.withValues(alpha: 0.65),
          crimsonColor.withValues(alpha: 0.16),
        ],
      );
      shadowColor = crimsonColor.withValues(alpha: 0.08);
    } else if (task.priority == 'medium') {
      final amberColor = Colors.amber;
      borderGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          amberColor.withValues(alpha: 0.55),
          amberColor.withValues(alpha: 0.12),
        ],
      );
      shadowColor = amberColor.withValues(alpha: 0.04);
    }

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 260),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.34,
        DismissDirection.endToStart: 0.34,
      },
      background: const _SwipeActionBackground(
        icon: Icons.check_circle_rounded,
        alignment: Alignment.centerLeft,
        startColor: Color(0x33C8B892),
        endColor: Color(0x889D8B63),
      ),
      secondaryBackground: const _SwipeActionBackground(
        icon: Icons.delete_forever_rounded,
        alignment: Alignment.centerRight,
        startColor: Color(0x33C7847D),
        endColor: Color(0x887F4D4A),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!task.isCompleted) {
            LifePilotGleamRegistry.trigger('task_${task.id}');
            await Future.delayed(const Duration(milliseconds: 100));
          }
          await ref.read(toggleTaskCompletionProvider)(task);
          return false;
        }
        final shouldDelete = await _confirmDelete(context);
        if (shouldDelete) {
          await ref
              .read(notificationServiceProvider)
              .cancel(taskReminderId(task.id));
          await database.deleteTask(task.id);
        }
        return false;
      },
      child: LifePilotGleam(
        gleamId: 'task_${task.id}',
        radius: 20,
        child: LifePilotGlassCard(
          radius: 20,
          padding: EdgeInsets.zero,
          borderGradient: borderGradient,
          shadowColor: shadowColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                minVerticalPadding: 14,
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) async {
                    if (!task.isCompleted) {
                      LifePilotGleamRegistry.trigger('task_${task.id}');
                      await Future.delayed(const Duration(milliseconds: 100));
                    }
                    await ref.read(toggleTaskCompletionProvider)(task);
                  },
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(
                        label: shortDate(task.dueDate),
                        color: overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                      ),
                      if (task.tags.isNotEmpty)
                        for (final tag in task.tags.split(','))
                          if (tag.trim().isNotEmpty) _CategoryBadge(tag: tag),
                      if (task.recurrencePattern != null &&
                          task.recurrencePattern != 'none')
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSubtasks)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    PopupMenuButton<String>(
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
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded && hasSubtasks
                    ? _SubtaskList(taskId: task.id)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This task will be removed from your local data.'),
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
    return confirmed == true;
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cleaned = tag.trim().toLowerCase();

    Color tintColor;
    switch (cleaned) {
      case 'work':
        tintColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        break;
      case 'personal':
        tintColor = theme.colorScheme.primary;
        break;
      case 'health':
      case 'urgent':
      case 'health/urgent':
        tintColor = const Color(0xFFE0516F);
        break;
      case 'ideas':
        tintColor = dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
        break;
      case 'finance':
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
        boxShadow: cleaned == 'personal'
            ? [
                BoxShadow(
                  color: tintColor.withValues(alpha: 0.08),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        tag.trim(),
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

class _SubtaskList extends ConsumerWidget {
  const _SubtaskList({required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(subtasksProvider(taskId));
    final db = ref.watch(appDatabaseProvider);

    return subtasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
          child: Column(
            children: [
              for (final subtask in items)
                _SubtaskTile(subtask: subtask, db: db),
            ],
          ),
        );
      },
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({required this.subtask, required this.db});

  final Subtask subtask;
  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: subtask.isCompleted,
              onChanged: (value) async {
                await db.toggleSubtask(subtask);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: subtask.isCompleted
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.icon,
    required this.alignment,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final Alignment alignment;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: alignment == Alignment.centerLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [startColor, endColor],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      child: Icon(icon, color: Colors.white),
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

class _DraftSubtask {
  _DraftSubtask({required this.title, this.isCompleted = false});
  String title;
  bool isCompleted;
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  late final TextEditingController _subtaskTitleController;
  late String _priority;
  late String _recurrencePattern;
  DateTime? _dueDate;
  DateTime? _reminderAt;

  List<String> _selectedCategories = [];
  List<_DraftSubtask> _subtasks = [];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _tags = TextEditingController(text: task?.tags ?? '');
    _subtaskTitleController = TextEditingController();
    _priority = task?.priority ?? 'medium';
    _recurrencePattern = task?.recurrencePattern ?? 'none';
    _dueDate = task?.dueDate;
    _reminderAt = task?.reminderAt;

    _selectedCategories =
        task?.tags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];

    if (task != null) {
      ref.read(appDatabaseProvider).watchSubtasksForTask(task.id).first.then((
        list,
      ) {
        if (mounted) {
          setState(() {
            _subtasks = list
                .map(
                  (s) =>
                      _DraftSubtask(title: s.title, isCompleted: s.isCompleted),
                )
                .toList();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    _subtaskTitleController.dispose();
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
            SatinGlassTextField(
              controller: _title,
              labelText: 'Title',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            SatinGlassTextField(
              controller: _description,
              labelText: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Categories',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in [
                  'Work',
                  'Personal',
                  'Ideas',
                  'Health',
                  'Finance',
                ])
                  _CategorySelectionChip(
                    category: category,
                    isSelected: _selectedCategories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                        _tags.text = _selectedCategories.join(',');
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SatinGlassTextField(
              controller: _tags,
              labelText: 'Additional tags (comma separated)',
            ),
            const SizedBox(height: 16),
            Text(
              'Sub-tasks',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _subtasks.length; i++)
              Row(
                children: [
                  Checkbox(
                    value: _subtasks[i].isCompleted,
                    onChanged: (val) {
                      setState(() {
                        _subtasks[i].isCompleted = val ?? false;
                      });
                    },
                  ),
                  Expanded(child: Text(_subtasks[i].title)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        _subtasks.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SatinGlassTextField(
                    controller: _subtaskTitleController,
                    labelText: 'Add a sub-task...',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final txt = _subtaskTitleController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _subtasks.add(_DraftSubtask(title: txt));
                        _subtaskTitleController.clear();
                      });
                    }
                  },
                ),
              ],
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final pattern in ['none', 'daily', 'weekly', 'monthly'])
                  ChoiceChip(
                    label: Text(switch (pattern) {
                      'none' => 'None',
                      'daily' => 'Daily',
                      'weekly' => 'Weekly',
                      'monthly' => 'Monthly',
                      _ => 'None',
                    }),
                    selected: _recurrencePattern == pattern,
                    selectedColor: const Color(
                      0xFF286C63,
                    ).withValues(alpha: 0.24),
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
      recurrencePattern: Value(
        _recurrencePattern == 'none' ? null : _recurrencePattern,
      ),
      recurrenceParentId: Value(existing?.recurrenceParentId),
    );
    final savedId = await database.saveTask(entry);
    final id = existing?.id ?? savedId;

    // Sync subtasks
    await database.customStatement('DELETE FROM subtasks WHERE parent_id = ?', [
      id,
    ]);
    for (final sub in _subtasks) {
      await database.saveSubtask(
        SubtasksCompanion.insert(
          title: sub.title,
          isCompleted: Value(sub.isCompleted),
          parentId: id,
        ),
      );
    }

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

class _CategorySelectionChip extends StatelessWidget {
  const _CategorySelectionChip({
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  final String category;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final cleaned = category.toLowerCase();
    Color tintColor;
    switch (cleaned) {
      case 'work':
        tintColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        break;
      case 'personal':
        tintColor = theme.colorScheme.primary;
        break;
      case 'health':
        tintColor = const Color(0xFFE0516F);
        break;
      case 'ideas':
        tintColor = dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
        break;
      case 'finance':
        tintColor = const Color(0xFF286C63);
        break;
      default:
        tintColor = theme.colorScheme.secondary;
    }

    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: tintColor.withValues(alpha: 0.25),
      checkmarkColor: tintColor,
      labelStyle: TextStyle(
        color: isSelected ? tintColor : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
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
