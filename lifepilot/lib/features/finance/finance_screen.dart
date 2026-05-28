import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_panel.dart';
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
          _AccountsList(currency: currency),
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
          const _FinancialTrendChart(),
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
    return LifePilotGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIcon(icon: icon, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
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
    final theme = Theme.of(context);
    return LifePilotGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs expense',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
                          getTitlesWidget: (val, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              val == 0 ? 'Income' : 'Expense',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                            width: 24,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                theme.colorScheme.primary,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY * 1.2,
                              color: Colors.white.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.05
                                    : 0.08,
                              ),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: value.expenses,
                            width: 24,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.error.withValues(alpha: 0.4),
                                theme.colorScheme.error,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY * 1.2,
                              color: Colors.white.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.05
                                    : 0.08,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
    return LifePilotGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category spending',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: summary.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(error: error),
              data: (value) {
                if (value.byCategory.isEmpty) {
                  return const Center(
                    child: Text('No expenses for this filter.'),
                  );
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
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      for (final entry in value.byCategory.entries)
                        PieChartSectionData(
                          value: entry.value,
                          title: entry.key,
                          radius: 50,
                          color: colors[index++ % colors.length],
                          titleStyle: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
    final accountsAsync = ref.watch(accountsStreamProvider);

    return SectionCard(
      title: 'Transaction history',
      child: entries.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No transactions found',
              message: 'Your ledger is empty for this filter range.',
            );
          }
          return accountsAsync.when(
            loading: () => const LoadingState(),
            error: (error, _) => ErrorState(error: error),
            data: (accountsList) {
              final accountMap = {for (final a in accountsList) a.id: a.name};

              return Column(
                children: [
                  for (final entry in items)
                    Dismissible(
                      key: ValueKey('tx-${entry.id}'),
                      direction: DismissDirection.horizontal,
                      movementDuration: const Duration(milliseconds: 260),
                      dismissThresholds: const {
                        DismissDirection.startToEnd: 0.34,
                        DismissDirection.endToStart: 0.34,
                      },
                      background: const _SwipeActionBackground(
                        icon: Icons.edit_rounded,
                        alignment: Alignment.centerLeft,
                        startColor: Color(0x3324E38A),
                        endColor: Color(0x8820C997),
                      ),
                      secondaryBackground: const _SwipeActionBackground(
                        icon: Icons.delete_forever_rounded,
                        alignment: Alignment.centerRight,
                        startColor: Color(0x33FF2E55),
                        endColor: Color(0x88A2122F),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          showTransactionForm(context, ref, entry: entry);
                          return false;
                        }
                        final shouldDelete = await _confirmDelete(context);
                        if (shouldDelete) {
                          await database.deleteFinanceEntryWithBalance(entry.id);
                        }
                        return false;
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: GlassIcon(
                          icon: entry.type == 'income'
                              ? Icons.arrow_downward_rounded
                              : entry.type == 'transfer'
                                  ? Icons.swap_horiz
                                  : Icons.arrow_upward_rounded,
                          color: entry.type == 'income'
                              ? Theme.of(context).colorScheme.primary
                              : entry.type == 'transfer'
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.error,
                        ),
                        title: Text(entry.title),
                        subtitle: Text(
                          entry.type == 'transfer'
                              ? 'Transfer: ${accountMap[entry.accountId] ?? 'Unknown'} ➔ ${accountMap[entry.transferTargetAccountId] ?? 'Unknown'} • ${shortDate(entry.date)}'
                              : '${entry.category} • ${accountMap[entry.accountId] ?? 'Primary'} • ${shortDate(entry.date)}',
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
                                  await database.deleteFinanceEntryWithBalance(
                                    entry.id,
                                  );
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
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
  int? _accountId;
  int? _transferTargetAccountId;

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
    _accountId = entry?.accountId;
    _transferTargetAccountId = entry?.transferTargetAccountId;
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
    final accountsAsync = ref.watch(accountsStreamProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Error loading accounts: $err')),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Please create an account first.')),
          );
        }

        _accountId ??= widget.entry?.accountId ?? accounts.first.id;
        if (_type == 'transfer') {
          _transferTargetAccountId ??=
              widget.entry?.transferTargetAccountId ??
              (accounts.length > 1 ? accounts[1].id : accounts.first.id);
        }

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
                    ButtonSegment(
                      value: 'transfer',
                      label: Text('Transfer'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) {
                    setState(() {
                      _type = value.first;
                    });
                  },
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
                DropdownButtonFormField<int>(
                  initialValue: _accountId,
                  decoration: InputDecoration(
                    labelText: _type == 'transfer' ? 'From Account' : 'Account',
                  ),
                  items: [
                    for (final acc in accounts)
                      DropdownMenuItem(value: acc.id, child: Text(acc.name)),
                  ],
                  onChanged: (value) => setState(() => _accountId = value),
                ),
                if (_type == 'transfer') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _transferTargetAccountId,
                    decoration: const InputDecoration(labelText: 'To Account'),
                    items: [
                      for (final acc in accounts)
                        DropdownMenuItem(value: acc.id, child: Text(acc.name)),
                    ],
                    onChanged: (value) =>
                        setState(() => _transferTargetAccountId = value),
                    validator: (val) {
                      if (val == _accountId) {
                        return 'Cannot transfer to the same account';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category in AppConstants.financeCategories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _category = value ?? 'Other'),
                  ),
                ],
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
      },
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
        category: Value(_type == 'transfer' ? 'Transfer' : _category),
        date: _date,
        note: Value(_note.text.trim()),
        type: Value(_type),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        accountId: Value(_accountId),
        transferTargetAccountId: Value(
          _type == 'transfer' ? _transferTargetAccountId : null,
        ),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Category budgets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final item in activeBudgets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryBudgetCard(item: item, currency: currency),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryBudgetCard extends StatefulWidget {
  const _CategoryBudgetCard({required this.item, required this.currency});

  final CategoryBudgetStatus item;
  final String currency;

  @override
  State<_CategoryBudgetCard> createState() => _CategoryBudgetCardState();
}

class _CategoryBudgetCardState extends State<_CategoryBudgetCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _initAnimationIfNeeded();
  }

  void _initAnimationIfNeeded() {
    if (widget.item.isOverLimit) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    } else {
      _pulseController?.dispose();
      _pulseController = null;
    }
  }

  @override
  void didUpdateWidget(covariant _CategoryBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initAnimationIfNeeded();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildCardContent(double pulseVal) {
      LinearGradient? cardGrad;
      LinearGradient? borderGrad;
      Color? shadowCol;

      if (widget.item.isOverLimit) {
        final alphaFactor = 0.36 + (pulseVal * 0.44); // 0.36 to 0.80
        final shadowAlpha = 0.08 + (pulseVal * 0.16); // 0.08 to 0.24
        final crimsonColor = const Color(0xFFFF2E55);

        cardGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            crimsonColor.withValues(alpha: 0.14),
            crimsonColor.withValues(alpha: 0.03),
          ],
        );
        borderGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            crimsonColor.withValues(alpha: alphaFactor),
            crimsonColor.withValues(alpha: alphaFactor * 0.25),
          ],
        );
        shadowCol = crimsonColor.withValues(alpha: shadowAlpha);
      } else if (widget.item.isNearLimit) {
        final amberColor = Colors.amber;

        cardGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            amberColor.withValues(alpha: 0.08),
            amberColor.withValues(alpha: 0.02),
          ],
        );
        borderGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            amberColor.withValues(alpha: 0.46),
            amberColor.withValues(alpha: 0.12),
          ],
        );
        shadowCol = amberColor.withValues(alpha: 0.10);
      }

      return LifePilotGlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        cardGradient: cardGrad,
        borderGradient: borderGrad,
        shadowColor: shadowCol,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(
                        widget.item.category.colorValue,
                      ).withValues(alpha: 0.2),
                      radius: 12,
                      child: Icon(
                        Icons.circle,
                        color: Color(widget.item.category.colorValue),
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${money(widget.item.spent, widget.currency)} / ${money(widget.item.budget, widget.currency)}',
                  style: TextStyle(
                    color: widget.item.isOverLimit
                        ? theme.colorScheme.error
                        : widget.item.isNearLimit
                        ? Colors.amber[800]
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        widget.item.isNearLimit || widget.item.isOverLimit
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.item.ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.38),
                color: widget.item.isOverLimit
                    ? theme.colorScheme.error
                    : widget.item.isNearLimit
                    ? Colors.amber
                    : Color(widget.item.category.colorValue),
              ),
            ),
            if (widget.item.isOverLimit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Exceeded budget limit by ${money(widget.item.spent - widget.item.budget, widget.currency)}!',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.item.isNearLimit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nearing limit! ${(widget.item.ratio * 100).toStringAsFixed(0)}% budget depleted.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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

    if (_pulseController != null) {
      return AnimatedBuilder(
        animation: _pulseController!,
        builder: (context, child) => buildCardContent(_pulseController!.value),
      );
    } else {
      return buildCardContent(0.0);
    }
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
  ConsumerState<_BudgetSettingsForm> createState() =>
      _BudgetSettingsFormState();
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
                final financeCats = items
                    .where((c) => c.type == 'finance' || c.type == 'both')
                    .toList();
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
                        text:
                            cat.monthlyBudget == null ||
                                cat.monthlyBudget == 0.0
                            ? ''
                            : cat.monthlyBudget.toString(),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(
                              cat.colorValue,
                            ).withValues(alpha: 0.2),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                    final double? budgetVal = budgetText.isEmpty
                        ? null
                        : double.parse(budgetText);

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
                      const SnackBar(
                        content: Text('Budgets updated successfully'),
                      ),
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

class _FinancialTrendChart extends ConsumerWidget {
  const _FinancialTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(financialTrendProvider);
    final theme = Theme.of(context);
    final currency =
        ref.watch(settingsControllerProvider).valueOrNull?.currency ?? 'LKR';
    final dark = theme.brightness == Brightness.dark;

    return LifePilotGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Running monthly income vs expenses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: trendAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(error: error),
              data: (points) {
                if (points.isEmpty) {
                  return const Center(
                    child: Text('No transaction history for trend analysis.'),
                  );
                }

                final List<FlSpot> incomeSpots = [];
                final List<FlSpot> expenseSpots = [];

                for (int i = 0; i < points.length; i++) {
                  incomeSpots.add(FlSpot(i.toDouble(), points[i].income));
                  expenseSpots.add(FlSpot(i.toDouble(), points[i].expense));
                }

                final maxVal = points.fold<double>(0.0, (prev, p) {
                  final val = p.income > p.expense ? p.income : p.expense;
                  return val > prev ? val : prev;
                });

                final double maxY = maxVal > 0 ? maxVal * 1.25 : 100.0;

                final incomeColor = theme.colorScheme.primary;
                final expenseColor = theme.colorScheme.error;

                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withValues(
                              alpha: dark ? 0.08 : 0.12,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox();
                              }
                              final date = points[idx].month;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM yy').format(date),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                compactNumber(value),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: incomeSpots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [incomeColor, const Color(0xFF00F2FE)],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: incomeColor,
                                  strokeWidth: 2,
                                  strokeColor: theme.colorScheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                incomeColor.withValues(alpha: 0.24),
                                incomeColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: expenseSpots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [expenseColor, const Color(0xFFFF4B2B)],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: expenseColor,
                                  strokeWidth: 2,
                                  strokeColor: theme.colorScheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                expenseColor.withValues(alpha: 0.20),
                                expenseColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.90),
                          tooltipBorderRadius: BorderRadius.circular(12),
                          getTooltipItems: (touchedSpots) {
                            if (touchedSpots.isEmpty) return [];
                            final firstSpot = touchedSpots.first;
                            final idx = firstSpot.x.toInt();
                            if (idx < 0 || idx >= points.length) {
                              return touchedSpots.map((_) => null).toList();
                            }
                            final p = points[idx];
                            final netBalance = p.income - p.expense;
                            final balanceStr = netBalance >= 0
                                ? '+${money(netBalance, currency)}'
                                : money(netBalance, currency);

                            return touchedSpots.map((spot) {
                              if (spot == firstSpot) {
                                return LineTooltipItem(
                                  '${DateFormat('MMM yyyy').format(p.month)}\n'
                                  'Income: ${money(p.income, currency)}\n'
                                  'Expenses: ${money(p.expense, currency)}\n'
                                  'Net Balance: $balanceStr',
                                  theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ) ??
                                      const TextStyle(),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsList extends ConsumerWidget {
  const _AccountsList({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return accountsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts found',
            message: 'Create your first wallet to track cash flow.',
          );
        }
        return SectionCard(
          title: 'Accounts & Wallets',
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length + 1,
              itemBuilder: (context, index) {
                if (index == accounts.length) {
                  // Add Account Button
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 140,
                      child: OutlinedButton(
                        onPressed: () => _showAddAccountForm(context, ref),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_card_outlined),
                            SizedBox(height: 4),
                            Text('Add Account', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final acc = accounts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 150,
                    child: LifePilotGlassCard(
                      radius: 16,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(
                                  acc.colorValue,
                                ).withValues(alpha: 0.16),
                                radius: 8,
                                child: Icon(
                                  Icons.circle,
                                  color: Color(acc.colorValue),
                                  size: 6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  acc.name,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money(acc.currentBalance, currency),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddAccountForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassPanel(
        radius: 32,
        padding: EdgeInsets.zero,
        child: const _AddAccountForm(),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete transaction?'),
      content: const Text('This entry will be removed from your local ledger.'),
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
        borderRadius: BorderRadius.circular(22),
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

class _AddAccountForm extends ConsumerStatefulWidget {
  const _AddAccountForm();

  @override
  ConsumerState<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<_AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  int _selectedColor = 0xFF286C63;

  final List<int> _colors = [
    0xFF286C63,
    0xFF4B66D3,
    0xFFC77D2B,
    0xFF8A5CF6,
    0xFFE0516F,
    0xFF2E8B57,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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
              'Add Account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Account Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Initial Balance'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                if (double.tryParse(value) == null) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Accent Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final colorVal in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorVal),
                    child: CircleAvatar(
                      backgroundColor: Color(colorVal),
                      radius: 18,
                      child: _selectedColor == colorVal
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(appDatabaseProvider);
    final initial = double.tryParse(_balanceController.text) ?? 0.0;

    await db.saveAccount(
      AccountsCompanion.insert(
        name: _nameController.text.trim(),
        initialBalance: Value(initial),
        currentBalance: Value(initial),
        colorValue: Value(_selectedColor),
      ),
    );

    if (mounted) Navigator.pop(context);
  }
}
