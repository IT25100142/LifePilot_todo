import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/backup_summary.dart';
import '../../core/services/export_provider.dart';
import '../../core/utils/crypto_helpers.dart';
import '../../data/database/app_database.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/database_provider.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Settings'),
      ),
      body: settings.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (state) => Stack(
          children: [
            const Positioned.fill(child: _AmbientBackdrop()),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _SettingsGroupHeader('Appearance'),
                _ThemeSection(themeMode: state.themeMode),
                const SizedBox(height: 16),
                const _SettingsGroupHeader('Currency'),
                _CurrencySection(currency: state.currency),
                const SizedBox(height: 16),
                const _SettingsGroupHeader('Local data'),
                _DataSection(currency: state.currency),
                const SizedBox(height: 16),
                const _SettingsGroupHeader('About'),
                const _AboutSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroupHeader extends StatelessWidget {
  const _SettingsGroupHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how LifePilot follows your device theme.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _GlassSegmentedSelector<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: themeMode,
            onSelected: (value) {
              ref.read(settingsControllerProvider.notifier).setThemeMode(value);
            },
          ),
        ],
      ),
    );
  }
}

class _GlassSegmentedSelector<T> extends StatelessWidget {
  const _GlassSegmentedSelector({
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: segments.map((segment) {
          final isSelected = segment.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(segment.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(
                          alpha: dark ? 0.85 : 0.95,
                        )
                      : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(
                        (segment.icon as Icon).icon,
                        size: 16,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      (segment.label as Text).data ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CurrencySection extends ConsumerStatefulWidget {
  const _CurrencySection({required this.currency});

  final String currency;

  @override
  ConsumerState<_CurrencySection> createState() => _CurrencySectionState();
}

class _CurrencySectionState extends ConsumerState<_CurrencySection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currency);
  }

  @override
  void didUpdateWidget(covariant _CurrencySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      _controller.text = widget.currency;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default is LKR, but any short currency code works offline.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.monetization_on_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currency Code',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'LKR',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                color: theme.colorScheme.primary,
                tooltip: 'Save',
                onPressed: () {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setCurrency(_controller.text);
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);
    final service = ref.watch(exportServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final silverChevronColor = isDark
        ? const Color(0xFFC7C7CC)
        : const Color(0xFF8E8E93);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifePilotGlassCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            children: [
              _SettingsActionRow(
                title: 'Export Encrypted Backup',
                subtitle: 'Secure offline database clone',
                leadingIcon: Icons.data_object,
                trailing: Icon(Icons.chevron_right, color: silverChevronColor),
                onTap: () => _guard(context, () async {
                  final password = await _promptBackupPassword(context);
                  if (password == null) return;
                  await service.exportEncryptedBackup(
                    currency: currency,
                    password: password,
                  );
                }),
              ),
              _buildDivider(theme),
              _SettingsActionRow(
                title: 'Import Encrypted Backup',
                subtitle: 'Restore database from backup file',
                leadingIcon: Icons.upload_file,
                trailing: Icon(Icons.chevron_right, color: silverChevronColor),
                onTap: () => _guard(context, () async {
                  final password = await _promptImportPassword(context);
                  if (password == null) return;
                  final prepared = await service.prepareEncryptedBackupImport(
                    password: password,
                  );
                  if (prepared == null || !context.mounted) return;
                  final confirmed = await _confirmRestoreSummary(
                    context,
                    prepared.summary,
                  );
                  if (!confirmed || !context.mounted) return;
                  await service.applyPreparedBackupImport(prepared);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import complete')),
                    );
                  }
                }, showSuccess: false),
              ),
              _buildDivider(theme),
              _SettingsActionRow(
                title: 'Export CSV',
                subtitle: 'Spreadsheet friendly ledger data',
                leadingIcon: Icons.table_chart_outlined,
                trailing: Icon(Icons.chevron_right, color: silverChevronColor),
                onTap: () => _guard(context, service.exportCsv),
              ),
              _buildDivider(theme),
              _SettingsActionRow(
                title: 'Export JSON (legacy)',
                subtitle: 'Plain text data format',
                leadingIcon: Icons.insert_drive_file_outlined,
                trailing: Icon(Icons.chevron_right, color: silverChevronColor),
                onTap: () =>
                    _guard(context, () => service.exportJson(currency)),
              ),
              _buildDivider(theme),
              _SettingsActionRow(
                title: 'Import JSON (legacy)',
                subtitle: 'Load settings and transactions',
                leadingIcon: Icons.file_open_outlined,
                trailing: Icon(Icons.chevron_right, color: silverChevronColor),
                onTap: () => _guard(context, () async {
                  final imported = await service.importJson();
                  if (context.mounted && imported) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import complete')),
                    );
                  }
                }, showSuccess: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SettingsGroupHeader('Danger Zone'),
        _DestructiveActionTile(
          onTap: () => _confirmClear(context, database.clearAllData),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      indent: 52,
      endIndent: 8,
    );
  }

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action, {
    bool showSuccess = true,
  }) async {
    try {
      await action();
      if (context.mounted && showSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Done')));
      }
    } on BackupCryptoException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on BackupRestoreException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    Future<void> Function() clear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This removes tasks, events, transactions, categories, and settings from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      await _guard(context, clear);
    }
  }

  Future<String?> _promptBackupPassword(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create backup password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 8) {
                          return 'Password must be at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => obscureConfirm = !obscureConfirm);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, passwordController.text);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      passwordController.dispose();
      confirmController.dispose();
    });
    return result;
  }

  Future<String?> _promptImportPassword(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    bool obscure = true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Unlock encrypted backup'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Backup password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscure = !obscure);
                      },
                    ),
                  ),
                  validator: (value) {
                    if ((value?.isEmpty ?? true)) {
                      return 'Password is required.';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, controller.text);
                    }
                  },
                  child: const Text('Decrypt'),
                ),
              ],
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      controller.dispose();
    });
    return result;
  }

  Future<bool> _confirmRestoreSummary(
    BuildContext context,
    BackupSummary summary,
  ) async {
    final exportedMonth = _monthLabel(summary.exportedAt.month);
    final exportedText =
        '${summary.exportedAt.day} $exportedMonth ${summary.exportedAt.year}';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup date: $exportedText'),
            const SizedBox(height: 8),
            Text('Tasks: ${summary.taskCount}'),
            Text('Events: ${summary.eventCount}'),
            Text('Accounts: ${summary.accountCount}'),
            Text('Transactions: ${summary.transactionCount}'),
            if (summary.currency != null) Text('Currency: ${summary.currency}'),
            const SizedBox(height: 12),
            const Text(
              'This action will replace your current local data and cannot be undone.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace Data'),
          ),
        ],
      ),
    );
    return result == true;
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return months[month - 1];
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.title,
    required this.leadingIcon,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  leadingIcon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DestructiveActionTile extends StatefulWidget {
  const _DestructiveActionTile({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DestructiveActionTile> createState() => _DestructiveActionTileState();
}

class _DestructiveActionTileState extends State<_DestructiveActionTile> {
  bool _isHoveredOrPressed = false;

  @override
  Widget build(BuildContext context) {
    const crimsonText = Color(0xFFFF453A); // Bright iOS system red color

    final cardGradient = _isHoveredOrPressed
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withValues(alpha: 0.16),
              Colors.red.withValues(alpha: 0.04),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withValues(alpha: 0.06),
              Colors.red.withValues(alpha: 0.01),
            ],
          );

    final borderGradient = _isHoveredOrPressed
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.redAccent.withValues(alpha: 0.4),
              Colors.redAccent.withValues(alpha: 0.12),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.redAccent.withValues(alpha: 0.18),
              Colors.redAccent.withValues(alpha: 0.04),
            ],
          );

    final shadowColor = _isHoveredOrPressed
        ? Colors.red.withValues(alpha: 0.16)
        : Colors.red.withValues(alpha: 0.03);

    return LifePilotGlassCard(
      radius: 24,
      cardGradient: cardGradient,
      borderGradient: borderGradient,
      shadowColor: shadowColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHoveredOrPressed = true),
        onTapCancel: () => setState(() => _isHoveredOrPressed = false),
        onTapUp: (_) => setState(() => _isHoveredOrPressed = false),
        onHover: (hovered) => setState(() => _isHoveredOrPressed = hovered),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: crimsonText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clear data',
                      style: TextStyle(
                        color: crimsonText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This removes tasks, events, transactions, categories, and settings from this device.',
                      style: TextStyle(
                        color: crimsonText.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.warning_amber_rounded,
                color: crimsonText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: isDark ? 0.15 : 0.08,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}\nOffline-first productivity and finance app',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
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

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGlow = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );
    final secondaryGlow = theme.colorScheme.tertiary.withValues(
      alpha: isDark ? 0.14 : 0.08,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF060B0C) : const Color(0xFFF4FAFB),
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
