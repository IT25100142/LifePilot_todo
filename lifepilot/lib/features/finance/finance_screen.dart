import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../settings/settings_providers.dart';
import 'finance_providers.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pendingQuickActionProvider, (_, action) {
      if (action == QuickAction.transaction) {
        ref.read(pendingQuickActionProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTransactionForm(context, ref);
        });
      }
    });

    final currency =
        ref.watch(settingsControllerProvider).valueOrNull?.currency ?? 'LKR';
    final summary = ref.watch(financeSummaryProvider);
    final entries = ref.watch(filteredFinanceEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            tooltip: 'Manage Budgets',
            onPressed: () => showBudgetSettingsForm(context, ref),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            tooltip: 'Add transaction',
            onPressed: () => showTransactionForm(context, ref),
            icon: const Icon(Icons.add_card),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTransactionForm(context, ref),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Transaction'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _FinanceControls(),
          const SizedBox(height: 16),
          summary.when(
            loading: () => const LoadingState(),
            error: (error, _) => ErrorState(error: error),
            data: (value) => _SummaryCards(summary: value, currency: currency),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final children = [
                _IncomeExpenseChart(summary: summary),
                _CategoryChart(summary: summary),
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
          const SizedBox(height: 16),
          _CategoryBudgetStatusSection(currency: currency),
          const SizedBox(height: 16),
          _TransactionHistory(entries: entries, currency: currency),
        ],
      ),
    );
  }
}

class _FinanceControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedFinanceMonthProvider);
    return SectionCard(
      title: 'Monthly view',
      subtitle: monthLabel(selectedMonth),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () =>
                ref.read(selectedFinanceMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: () =>
                ref.read(selectedFinanceMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FinanceTypeFilter>(
                  initialValue: ref.watch(selectedFinanceTypeProvider),
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final type in FinanceTypeFilter.values)
                      DropdownMenuItem(value: type, child: Text(type.name)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedFinanceTypeProvider.notifier).state =
                          value;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: ref.watch(selectedFinanceCategoryProvider),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    for (final category in AppConstants.financeCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) =>
                      ref.read(selectedFinanceCategoryProvider.notifier).state =
                          value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary, required this.currency});

  final FinanceSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FinanceMetric(
            'Income',
            money(summary.income, currency),
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FinanceMetric(
            'Expenses',
            money(summary.expenses, currency),
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FinanceMetric(
            'Balance',
            money(summary.balance, currency),
            Icons.savings_outlined,
          ),
        ),
      ],
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIcon(icon: icon, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.summary});

  final AsyncValue<FinanceSummary> summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Income vs expense',
      child: SizedBox(
        height: 220,
        child: summary.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(error: error),
          data: (value) {
            final maxY = [
              value.income,
              value.expenses,
              1,
            ].reduce((a, b) => a > b ? a : b);
            return BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          Text(value == 0 ? 'Income' : 'Expense'),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: value.income,
                        width: 28,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: value.expenses,
                        width: 28,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.summary});

  final AsyncValue<FinanceSummary> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Category spending',
      child: SizedBox(
        height: 220,
        child: summary.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(error: error),
          data: (value) {
            if (value.byCategory.isEmpty) {
              return const Center(child: Text('No expenses for this filter.'));
            }
            final colors = [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary,
              theme.colorScheme.secondary,
              theme.colorScheme.error,
              theme.colorScheme.outline,
            ];
            var index = 0;
            return PieChart(
              PieChartData(
                sectionsSpace: 2,
                sections: [
                  for (final entry in value.byCategory.entries)
                    PieChartSectionData(
                      value: entry.value,
                      title: entry.key,
                      radius: 72,
                      color: colors[index++ % colors.length],
                      titleStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TransactionHistory extends ConsumerWidget {
  const _TransactionHistory({required this.entries, required this.currency});

  final AsyncValue<List<FinanceEntry>> entries;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);
    return SectionCard(
      title: 'Transaction history',
      child: entries.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (items) {
          if (items.isEmpty) {
            return const Text('No transactions match this filter.');
          }
          return Column(
            children: [
              for (final entry in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: GlassIcon(
                    icon: entry.type == 'income'
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: entry.type == 'income'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(entry.title),
                  subtitle: Text(
                    '${entry.category} • ${shortDate(entry.date)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        money(entry.amount, currency),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            showTransactionForm(context, ref, entry: entry);
                          } else if (value == 'delete') {
                            await database.deleteFinanceEntry(entry.id);
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
            ],
          );
        },
      ),
    );
  }
}

Future<void> showTransactionForm(
  BuildContext context,
  WidgetRef ref, {
  FinanceEntry? entry,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.zero,
      child: _TransactionForm(entry: entry),
    ),
  );
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({this.entry});

  final FinanceEntry? entry;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late String _type;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _amount = TextEditingController(text: entry?.amount.toString() ?? '');
    _note = TextEditingController(text: entry?.note ?? '');
    _category = entry?.category ?? 'Food';
    _type = entry?.type ?? 'expense';
    _date = entry?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
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
              widget.entry == null ? 'Add transaction' : 'Edit transaction',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in AppConstants.financeCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            InputChip(
              avatar: const Icon(Icons.today, size: 18),
              label: Text('${shortDate(_date)} ${_date.year}'),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save transaction'),
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
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final existing = widget.entry;
    await ref.read(saveFinanceTransactionProvider)(
      FinanceEntriesCompanion.insert(
        id: existing == null ? const Value.absent() : Value(existing.id),
        title: _title.text.trim(),
        amount: double.parse(_amount.text),
        category: Value(_category),
        date: _date,
        note: Value(_note.text.trim()),
        type: Value(_type),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _CategoryBudgetStatusSection extends ConsumerWidget {
  const _CategoryBudgetStatusSection({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusListAsync = ref.watch(categoryBudgetStatusProvider);
    final theme = Theme.of(context);

    return statusListAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (items) {
        final activeBudgets = items.where((item) => item.hasBudget).toList();
        if (activeBudgets.isEmpty) {
          return const SizedBox();
        }

        return SectionCard(
          title: 'Category budgets',
          subtitle: 'Monthly spending status',
          child: Column(
            children: [
              for (final item in activeBudgets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(item.category.colorValue).withValues(alpha: 0.2),
                                radius: 12,
                                child: Icon(
                                  Icons.circle,
                                  color: Color(item.category.colorValue),
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.category.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${money(item.spent, currency)} / ${money(item.budget, currency)}',
                            style: TextStyle(
                              color: item.isOverLimit
                                  ? theme.colorScheme.error
                                  : item.isNearLimit
                                      ? Colors.amber[800]
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight: item.isNearLimit || item.isOverLimit
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.ratio.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
                          color: item.isOverLimit
                              ? theme.colorScheme.error
                              : item.isNearLimit
                                  ? Colors.amber
                                  : Color(item.category.colorValue),
                        ),
                      ),
                      if (item.isOverLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Exceeded budget limit by ${money(item.spent - item.budget, currency)}!',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (item.isNearLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Nearing limit! ${(item.ratio * 100).toStringAsFixed(0)}% budget depleted.',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showBudgetSettingsForm(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.zero,
      child: const _BudgetSettingsForm(),
    ),
  );
}

class _BudgetSettingsForm extends ConsumerStatefulWidget {
  const _BudgetSettingsForm();

  @override
  ConsumerState<_BudgetSettingsForm> createState() => _BudgetSettingsFormState();
}

class _BudgetSettingsFormState extends ConsumerState<_BudgetSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <int, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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
              'Manage Budgets',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Set monthly spending limits per category.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const LoadingState(),
              error: (err, _) => ErrorState(error: err),
              data: (items) {
                final financeCats = items.where((c) => c.type == 'finance' || c.type == 'both').toList();
                if (financeCats.isEmpty) {
                  return const Text('No finance categories found.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: financeCats.length,
                  itemBuilder: (context, index) {
                    final cat = financeCats[index];
                    final controller = _controllers.putIfAbsent(
                      cat.id,
                      () => TextEditingController(
                        text: cat.monthlyBudget == null || cat.monthlyBudget == 0.0
                            ? ''
                            : cat.monthlyBudget.toString(),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(cat.colorValue).withValues(alpha: 0.2),
                            radius: 18,
                            child: Icon(
                              Icons.category,
                              color: Color(cat.colorValue),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'No budget limit',
                                labelText: 'Monthly limit',
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final val = double.tryParse(value);
                                  if (val == null || val < 0) {
                                    return 'Invalid';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final db = ref.read(appDatabaseProvider);
                final categoriesAsync = ref.read(categoriesStreamProvider);

                categoriesAsync.whenData((items) async {
                  for (final cat in items) {
                    final controller = _controllers[cat.id];
                    if (controller == null) continue;
                    final budgetText = controller.text.trim();
                    final double? budgetVal = budgetText.isEmpty ? null : double.parse(budgetText);

                    await db.saveCategory(
                      CategoriesCompanion(
                        id: Value(cat.id),
                        name: Value(cat.name),
                        type: Value(cat.type),
                        colorValue: Value(cat.colorValue),
                        iconName: Value(cat.iconName),
                        monthlyBudget: Value(budgetVal),
                      ),
                    );
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budgets updated successfully')),
                    );
                  }
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Save budgets'),
            ),
          ],
        ),
      ),
    );
  }
}
