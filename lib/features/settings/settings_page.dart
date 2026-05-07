import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/haptics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import '../auth/biometric_providers.dart';
import '../export/csv_exporter.dart';
import '../export/json_exporter.dart';
import '../export/qr_share_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          _SectionHeader(label: l.settingsTheme),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.settingsTheme),
            subtitle: Text(_themeLabel(settings.themeMode, l)),
            onTap: () async {
              final next = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => _ThemePickerSheet(current: settings.themeMode),
              );
              if (next != null) await settingsRepo.update(themeMode: next);
            },
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.colorize_outlined),
            title: Text(l.settingsDynamicColor),
            value: settings.useDynamicColor,
            onChanged: (v) => settingsRepo.update(useDynamicColor: v),
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.motion_photos_off),
            title: Text(l.settingsReducedMotion),
            value: settings.reducedMotion,
            onChanged: (v) => settingsRepo.update(reducedMotion: v),
          ),
          const Divider(),
          _SectionHeader(label: l.settingsLanguage),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            subtitle: Text(
              settings.locale == 'hi' ? l.languageHindi : l.languageEnglish,
            ),
            onTap: () async {
              final next = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => _LanguagePickerSheet(current: settings.locale),
              );
              if (next != null) await settingsRepo.update(locale: next);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text(settings.currencyCode),
            onTap: () async {
              final next = await showModalBottomSheet<String>(
                context: context,
                builder: (_) =>
                    _CurrencyPickerSheet(current: settings.currencyCode),
              );
              if (next != null) await settingsRepo.update(currencyCode: next);
            },
          ),
          const Divider(),
          const _SectionHeader(label: 'Security'),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.fingerprint),
            title: Text(l.settingsBiometric),
            value: settings.biometricEnabled,
            onChanged: (v) async {
              if (v) {
                final svc = ref.read(biometricServiceProvider);
                if (!await svc.isAvailable()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric unavailable on this device.'),
                      ),
                    );
                  }
                  return;
                }
                final ok = await svc.authenticate(reason: l.biometricPrompt);
                if (!ok) return;
              }
              await settingsRepo.update(biometricEnabled: v);
            },
          ),
          const Divider(),
          const _SectionHeader(label: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l.exportJson),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l.exportCsv),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(l.exportQr),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const QrSharePage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l.restoreFromFile),
            onTap: () => _restore(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Wipe all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _wipe(context, ref),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String mode, AppLocalizations l) {
    return switch (mode) {
      'light' => l.themeLight,
      'dark' => l.themeDark,
      _ => l.themeSystem,
    };
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final db = ref.read(hiveDatabaseProvider);
    final file = await JsonSnapshot(db).writeToFile();
    await ref
        .read(settingsRepositoryProvider)
        .update(lastBackupAt: DateTime.now());
    await Share.shareXFiles([XFile(file.path)], text: 'FinTrack Pro backup');
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(hiveDatabaseProvider);
    final localeTag = ref.read(settingsProvider).locale;
    final file = await CsvExporter(db).exportTransactions(localeTag: localeTag);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'FinTrack Pro transactions CSV');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final svc = ref.read(biometricServiceProvider);
    if (await svc.isAvailable()) {
      final ok = await svc.authenticate(reason: 'Confirm restore');
      if (!ok) return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.restoreFromFile),
        content: const Text(
          'This will replace all current data with the contents of the backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.restoreFromFile),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final content = await File(path).readAsString();
      final db = ref.read(hiveDatabaseProvider);
      final imported = await JsonImporter(db).importFromString(content);
      await Haptics.success();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored $imported transactions.')),
        );
      }
    } catch (e) {
      await Haptics.error();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final svc = ref.read(biometricServiceProvider);
    if (await svc.isAvailable()) {
      final ok = await svc.authenticate(reason: 'Confirm wipe');
      if (!ok) return;
    }
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Wipe all data?'),
        content: const Text(
          'This permanently deletes all transactions, categories, and budgets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await ref.read(hiveDatabaseProvider).clearAll();
    await Haptics.warning();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!context.mounted) return;
    context.go('/dashboard');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in [
            ('system', l.themeSystem, Icons.brightness_auto),
            ('light', l.themeLight, Icons.light_mode),
            ('dark', l.themeDark, Icons.dark_mode),
          ])
            ListTile(
              leading: Icon(entry.$3),
              title: Text(entry.$2),
              trailing: current == entry.$1 ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, entry.$1),
            ),
        ],
      ),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l.languageEnglish),
            trailing: current == 'en' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, 'en'),
          ),
          ListTile(
            title: Text(l.languageHindi),
            trailing: current == 'hi' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, 'hi'),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.current});
  final String current;

  static const _currencies = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'JPY',
    'CNY',
    'AUD',
    'CAD',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final c in _currencies)
            ListTile(
              title: Text(c),
              trailing: current == c ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, c),
            ),
        ],
      ),
    );
  }
}
