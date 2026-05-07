import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/hero_tags.dart';
import '../../core/utils/icon_helper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/transactions_providers.dart';
import 'add_transaction_flow.dart';

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.watch(transactionRepositoryProvider);
    ref.watch(transactionsStreamProvider);
    final tx = repo.byId(id);
    if (tx == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('${l.delete}: $id')),
      );
    }
    final category = ref.watch(categoriesMapProvider)[tx.categoryId];
    final fmt = ref.watch(currencyFormatterProvider);
    final localeTag = ref.watch(settingsProvider).locale;
    final color =
        category != null ? Color(category.colorValue) : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? l.tabTransactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AddTransactionFlow.show(context, editing: tx),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.delete),
                  content: const Text('Delete this transaction?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.delete),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await Haptics.warning();
                await repo.delete(tx.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Hero(
              tag: HeroTags.category(tx.categoryId),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  iconForCodePoint(
                    category?.iconCodePoint ?? Icons.help_outline.codePoint,
                  ),
                  size: 44,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${tx.isIncome ? '+' : '-'}${fmt.format(tx.amount)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tx.isIncome
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l.date),
                  trailing: Text(
                    DateHelpers.formatDateTime(tx.date, localeTag),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(l.category),
                  trailing: Text(category?.name ?? '—'),
                ),
                if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notes_outlined),
                    title: Text(l.notes),
                    subtitle: Text(tx.notes!),
                  ),
                ],
                if (tx.recurringRuleId != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.autorenew),
                    title: Text(l.recurring),
                    subtitle: const Text('Generated from a recurring rule'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (tx.receiptPath != null && File(tx.receiptPath!).existsSync())
            Hero(
              tag: HeroTags.receipt(tx.id),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(tx.receiptPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
