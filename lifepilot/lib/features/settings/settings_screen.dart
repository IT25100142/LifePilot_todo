import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/backup_summary.dart';
import '../../core/services/exchange_rate_provider.dart';
import '../../core/services/export_provider.dart';
import '../../core/utils/crypto_helpers.dart';
import '../../data/database/app_database.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/database_provider.dart';
import '../theme/theme_provider.dart';
import '../canvas_studio/canvas_studio_provider.dart';
import '../canvas_studio/grid_provider.dart';
import '../../core/theme/theme_customizer_provider.dart';
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
                const _MeshThemeSection(),
                const SizedBox(height: 16),
                const _GlassPhysicsStudioSection(),
                const SizedBox(height: 16),
                const _DashboardGridManagerSection(),
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
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 12,
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

class _CurrencySectionState extends ConsumerState<_CurrencySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _syncPressController;
  late final Animation<double> _syncPressScale;

  @override
  void initState() {
    super.initState();
    _syncPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _syncPressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _syncPressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _syncPressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch exchange rate provider
    final syncState = ref.watch(exchangeRateProvider);
    final isSyncing = syncState.status == ExchangeRateSyncStatus.syncing;

    // Format last sync time helper
    String getSyncTimeString(DateTime? lastSyncTime) {
      if (lastSyncTime == null) return 'Never synced';
      final now = DateTime.now();
      final difference = now.difference(lastSyncTime);
      if (difference.inSeconds < 60) {
        return 'Rates up to date • Just now';
      } else if (difference.inMinutes < 60) {
        return 'Last updated: ${difference.inMinutes}m ago';
      } else {
        final hour = lastSyncTime.hour.toString().padLeft(2, '0');
        final minute = lastSyncTime.minute.toString().padLeft(2, '0');
        return 'Last updated: $hour:$minute';
      }
    }

    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description ──
          Text(
            'Choose your default currency for transactions and sync real-time market rates.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // ── Selector row ──
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
                child: Text(
                  'Default Currency',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.currency,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  alignment: AlignmentDirectional.centerEnd,
                  items: [
                    for (final code in AppConstants.supportedCurrencyCodes)
                      DropdownMenuItem(
                        value: code,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            code,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setCurrency(value);
                  },
                ),
              ),
            ],
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              height: 1,
            ),
          ),

          // ── Sync status & action row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon & details
              Expanded(
                child: Row(
                  children: [
                    // Dynamic Sync status Icon
                    switch (syncState.status) {
                      ExchangeRateSyncStatus.syncing => const _SpinningIcon(
                        icon: Icons.sync,
                        color: Colors.grey,
                      ),
                      ExchangeRateSyncStatus.synced => const Icon(
                        Icons.check_circle_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                      ExchangeRateSyncStatus.offlineErrorFallback => const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    },
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (syncState.status) {
                              ExchangeRateSyncStatus.syncing =>
                                'Syncing latest rates...',
                              ExchangeRateSyncStatus.synced => 'Exchange Rates',
                              ExchangeRateSyncStatus.offlineErrorFallback =>
                                'Offline Fallback',
                            },
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            switch (syncState.status) {
                              ExchangeRateSyncStatus.syncing =>
                                'Updating from server...',
                              ExchangeRateSyncStatus.synced =>
                                getSyncTimeString(syncState.lastSyncTime),
                              ExchangeRateSyncStatus.offlineErrorFallback =>
                                'Offline • Using cached rates',
                            },
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Tactile Sync Now Button
              GestureDetector(
                onTapDown: isSyncing
                    ? null
                    : (_) => _syncPressController.forward(),
                onTapCancel: isSyncing
                    ? null
                    : () => _syncPressController.reverse(),
                onTapUp: isSyncing
                    ? null
                    : (_) {
                        _syncPressController.reverse();
                        ref.read(exchangeRateProvider.notifier).fetchRates();
                      },
                child: ScaleTransition(
                  scale: _syncPressScale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSyncing
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSyncing
                            ? Colors.transparent
                            : theme.colorScheme.primary.withValues(alpha: 0.24),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSyncing ? 'Syncing...' : 'Sync Now',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSyncing
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    const dangerText = Color(0xFFA36562);

    final cardGradient = _isHoveredOrPressed
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD19994).withValues(alpha: 0.20),
              const Color(0xFF8F6764).withValues(alpha: 0.06),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD19994).withValues(alpha: 0.10),
              const Color(0xFF8F6764).withValues(alpha: 0.03),
            ],
          );

    final borderGradient = _isHoveredOrPressed
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD9A79B).withValues(alpha: 0.48),
              const Color(0xFF9C7A75).withValues(alpha: 0.16),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD9A79B).withValues(alpha: 0.24),
              const Color(0xFF9C7A75).withValues(alpha: 0.08),
            ],
          );

    final shadowColor = _isHoveredOrPressed
        ? const Color(0xFF8A6661).withValues(alpha: 0.20)
        : const Color(0xFF8A6661).withValues(alpha: 0.08);

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
                  color: const Color(0xFFC69288).withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: dangerText,
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
                        color: dangerText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This removes tasks, events, transactions, categories, and settings from this device.',
                      style: TextStyle(
                        color: dangerText.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.warning_amber_rounded,
                color: dangerText,
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

class _AmbientBackdrop extends ConsumerWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customizer = ref.watch(themeCustomizerProvider);
    final tint = customizer.backdropTintColor;

    final primaryGlow = const Color(
      0xFFD6BD92,
    ).withValues(alpha: isDark ? 0.12 : 0.10);
    final secondaryGlow = const Color(
      0xFFC8A97A,
    ).withValues(alpha: isDark ? 0.10 : 0.08);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: tint, end: tint),
      duration: const Duration(milliseconds: 300),
      builder: (context, animatedTint, child) {
        final currentTint = animatedTint ?? tint;
        final baseColor = isDark
            ? Color.alphaBlend(
                currentTint.withValues(alpha: 0.5),
                const Color(0xFF151316),
              )
            : Color.alphaBlend(
                currentTint.withValues(alpha: 0.1),
                const Color(0xFFF7F3EC),
              );
        return Stack(
          children: [
            Positioned.fill(child: Container(color: baseColor)),
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
      },
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    final isTesting =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTesting) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member Signature Theme Palette Selector Section
// ─────────────────────────────────────────────────────────────────────────────

class _MeshThemeSection extends ConsumerStatefulWidget {
  const _MeshThemeSection();

  @override
  ConsumerState<_MeshThemeSection> createState() => _MeshThemeSectionState();
}

class _MeshThemeSectionState extends ConsumerState<_MeshThemeSection> {
  late final LifePilotGleamController _gleamController;

  @override
  void initState() {
    super.initState();
    _gleamController = LifePilotGleamController();
  }

  @override
  void dispose() {
    _gleamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeProfile = ref.watch(themePaletteProvider);
    final goldColor = const Color(0xFFD6BD92);

    return LifePilotGleam(
      controller: _gleamController,
      radius: 24,
      child: LifePilotGlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEMBER SIGNATURE PROFILE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: goldColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Customize the kinetic mesh background profile.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final profile in LifePilotPaletteProfile.values) ...[
                  GestureDetector(
                    onTap: () {
                      if (activeProfile != profile) {
                        ref
                            .read(themePaletteProvider.notifier)
                            .setPaletteProfile(profile);
                        _gleamController.trigger();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withValues(
                          alpha: activeProfile == profile ? 0.08 : 0.03,
                        ),
                        border: Border.all(
                          color: activeProfile == profile
                              ? goldColor
                              : Colors.white.withValues(alpha: 0.12),
                          width: activeProfile == profile ? 2.0 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 48,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: LinearGradient(
                            colors: [
                              meshPaletteConfig[profile]!.primary,
                              meshPaletteConfig[profile]!.secondary,
                              meshPaletteConfig[profile]!.tertiary,
                            ],
                          ),
                          boxShadow: activeProfile == profile
                              ? [
                                  BoxShadow(
                                    color: meshPaletteConfig[profile]!.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Physics Studio Customizer Section
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPhysicsStudioSection extends ConsumerWidget {
  const _GlassPhysicsStudioSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customizer = ref.watch(themeCustomizerProvider);
    final notifier = ref.read(themeCustomizerProvider.notifier);
    final goldColor = const Color(0xFFD6BD92);

    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GLASS PHYSICS STUDIO',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: goldColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fine-tune the physical material properties of the interface in real-time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Glass Blur Scale Slider
          _buildSliderRow(
            context: context,
            label: 'Glass Blur Scale',
            value: customizer.glassBlurScale,
            min: 0.0,
            max: 30.0,
            displayValue: customizer.glassBlurScale.toStringAsFixed(1),
            onChanged: (val) => notifier.setGlassBlurScale(val),
          ),
          const SizedBox(height: 16),

          // Surface Opacity Slider
          _buildSliderRow(
            context: context,
            label: 'Surface Opacity',
            value: customizer.surfaceOpacity,
            min: 0.05,
            max: 0.60,
            displayValue: customizer.surfaceOpacity.toStringAsFixed(2),
            onChanged: (val) => notifier.setSurfaceOpacity(val),
          ),
          const SizedBox(height: 16),

          // Specular & Grain Intensity Slider
          _buildSliderRow(
            context: context,
            label: 'Specular & Grain Intensity',
            value: customizer.specularGrainIntensity,
            min: 0.0,
            max: 1.0,
            displayValue: customizer.specularGrainIntensity.toStringAsFixed(2),
            onChanged: (val) => notifier.setSpecularGrainIntensity(val),
          ),
          const SizedBox(height: 16),

          // Backdrop Tint Color Chips Selector
          Text(
            'Backdrop Tint Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final color in const [
                Color(0xFF0F0E11), // Deep Obsidian
                Color(0xFF0D1B2A), // Midnight Navy
                Color(0xFF14121F), // Dark Indigo
                Color(0xFF1A0E1B), // Royal Plum
                Color(0xFF0E1A14), // Forest Emerald
              ]) ...[
                GestureDetector(
                  onTap: () => notifier.setBackdropTintColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: customizer.backdropTintColor == color
                            ? goldColor
                            : Colors.white.withValues(alpha: 0.2),
                        width: customizer.backdropTintColor == color
                            ? 2.0
                            : 1.0,
                      ),
                      boxShadow: customizer.backdropTintColor == color
                          ? [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.1,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            valueIndicatorColor: theme.colorScheme.primary,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Grid Manager Section
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardGridManagerSection extends ConsumerWidget {
  const _DashboardGridManagerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final grid = ref.watch(gridProvider);
    final notifier = ref.read(gridProvider.notifier);
    final customizer = ref.watch(themeCustomizerProvider);
    final goldColor = const Color(0xFFD6BD92);

    final cardKeys = [
      {
        'key': 'runway',
        'label': 'Predictive Fiscal Runway',
        'desc': 'Displays days of remaining fiscal runway',
        'icon': Icons.insights_rounded,
      },
      {
        'key': 'tasks',
        'label': 'Urgent Tasks List',
        'desc': 'Displays priority pending checklist items',
        'icon': Icons.checklist_rounded,
      },
      {
        'key': 'habits',
        'label': 'Habit Consistency Heatmap',
        'desc': 'Displays current streak and history grid',
        'icon': Icons.grid_on_rounded,
      },
      {
        'key': 'focus',
        'label': 'Quick Focus Deck',
        'desc': 'Displays deep work quick entry timers',
        'icon': Icons.timer_rounded,
      },
    ];

    return LifePilotGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DASHBOARD GRID MANAGER',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: goldColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toggle visible widgets and set layout density for your main dashboard.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),

          // Layout Density Selector
          Text(
            'LAYOUT PRESENTATION DENSITY',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 8),
          _GlassSegmentedSelector<String>(
            segments: const [
              ButtonSegment(
                value: 'Zen',
                label: Text('Zen'),
                icon: Icon(Icons.spa_outlined),
              ),
              ButtonSegment(
                value: 'Executive',
                label: Text('Executive'),
                icon: Icon(Icons.analytics_outlined),
              ),
            ],
            selected: customizer.interfaceDensity,
            onSelected: (value) {
              ref
                  .read(themeCustomizerProvider.notifier)
                  .setInterfaceDensity(value);
            },
          ),

          const SizedBox(height: 20),
          Divider(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: 16),

          Text(
            'VISIBLE COMPONENT TILES',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 8),

          for (int i = 0; i < cardKeys.length; i++) ...[
            _GridToggleRow(
              title: cardKeys[i]['label'] as String,
              subtitle: cardKeys[i]['desc'] as String,
              icon: cardKeys[i]['icon'] as IconData,
              value: grid.visibleCards[cardKeys[i]['key']] ?? true,
              onChanged: (visible) {
                notifier.setCardVisible(cardKeys[i]['key'] as String, visible);
              },
            ),
            if (i < cardKeys.length - 1)
              Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                height: 1,
                indent: 48,
              ),
          ],
        ],
      ),
    );
  }
}

class _GridToggleRow extends StatelessWidget {
  const _GridToggleRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.65,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
