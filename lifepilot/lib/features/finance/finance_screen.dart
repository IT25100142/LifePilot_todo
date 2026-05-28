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
    final database = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final existing = widget.entry;
    await database.saveFinanceEntry(
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
