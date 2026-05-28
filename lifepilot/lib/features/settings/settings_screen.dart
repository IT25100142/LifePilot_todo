import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/crypto_helpers.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/database/database_provider.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(error: error),
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ThemeSection(themeMode: state.themeMode),
            const SizedBox(height: 16),
            _CurrencySection(currency: state.currency),
            const SizedBox(height: 16),
            _DataSection(currency: state.currency),
            const SizedBox(height: 16),
            const _AboutSection(),
          ],
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
    return SectionCard(
      title: 'Appearance',
      subtitle: 'Choose how LifePilot follows your device theme.',
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(6),
        child: SegmentedButton<ThemeMode>(
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
          selected: {themeMode},
          onSelectionChanged: (selection) {
            ref
                .read(settingsControllerProvider.notifier)
                .setThemeMode(selection.first);
          },
        ),
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
    return SectionCard(
      title: 'Currency',
      subtitle: 'Default is LKR, but any short currency code works offline.',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Currency code',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(settingsControllerProvider.notifier)
                  .setCurrency(_controller.text);
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
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
    final service = ExportService(database);

    return SectionCard(
      title: 'Local data',
      subtitle:
          'Export, import, or clear the SQLite data stored on this device.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _guard(context, () async {
              final password = await _promptBackupPassword(context);
              if (password == null) return;
              await service.exportEncryptedBackup(
                currency: currency,
                password: password,
              );
            }),
            icon: const Icon(Icons.data_object),
            label: const Text('Export Encrypted Backup'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _guard(context, service.exportCsv),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export CSV'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _guard(context, () async {
              final password = await _promptImportPassword(context);
              if (password == null) return;
              final imported = await service.importEncryptedBackup(
                password: password,
              );
              if (context.mounted && imported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import complete')),
                );
              }
            }),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Encrypted Backup'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _guard(context, () => service.exportJson(currency)),
            icon: const Icon(Icons.insert_drive_file_outlined),
            label: const Text('Export JSON (legacy)'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _guard(context, () async {
              final imported = await service.importJson();
              if (context.mounted && imported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import complete')),
                );
              }
            }),
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import JSON (legacy)'),
          ),
          OutlinedButton.icon(
            onPressed: () => _confirmClear(context, database.clearAllData),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Clear data'),
          ),
        ],
      ),
    );
  }

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) {
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

    passwordController.dispose();
    confirmController.dispose();
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

    controller.dispose();
    return result;
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'About',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.flight_takeoff_rounded),
        title: Text(AppConstants.appName),
        subtitle: Text(
          'Version ${AppConstants.appVersion}\nOffline-first productivity and finance app',
        ),
      ),
    );
  }
}
