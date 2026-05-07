import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/hero_tags.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/categories_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/transactions_providers.dart';

class TransactionsListPage extends ConsumerWidget {
  const TransactionsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final txAsync = ref.watch(transactionsStreamProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final localeTag = ref.watch(settingsProvider).locale;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider(selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabTransactions),
      ),
      body: txAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('$e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return _EmptyState(l: l);
          }
          final grouped = _groupByDate(transactions);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            itemCount: grouped.length + 1,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Hero(
                    tag: HeroTags.summaryTotal,
                    flightShuttleBuilder: (_, _, _, _, _) =>
                        Material(
                      color: Colors.transparent,
                      child: Text(
                        fmt.format(summary.totalSpent),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateHelpers.formatMonth(selectedMonth, localeTag),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt.format(summary.totalSpent),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l.transactionsThisMonth(
                                _countInMonth(transactions, selectedMonth)),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final group = grouped[idx - 1];
              return _DateGroupSection(
                group: group,
                fmt: fmt,
                localeTag: localeTag,
                categoriesMap: categoriesMap,
              );
            },
          );
        },
      ),
    );
  }

  int _countInMonth(List<TransactionModel> txns, DateTime month) {
    return txns
        .where((t) =>
            t.date.year == month.year && t.date.month == month.month)
        .length;
  }

  List<_DateGroup> _groupByDate(List<TransactionModel> txns) {
    final out = <DateTime, List<TransactionModel>>{};
    for (final t in txns) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      out.putIfAbsent(key, () => []).add(t);
    }
    final keys = out.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final k in keys)
        _DateGroup(date: k, items: out[k]!),
    ];
  }
}

class _DateGroup {
  _DateGroup({required this.date, required this.items});

  final DateTime date;
  final List<TransactionModel> items;
}

class _DateGroupSection extends StatelessWidget {
  const _DateGroupSection({
    required this.group,
    required this.fmt,
    required this.localeTag,
    required this.categoriesMap,
  });

  final _DateGroup group;
  final dynamic fmt;
  final String localeTag;
  final Map<String, CategoryModel> categoriesMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            DateHelpers.formatRelative(group.date, localeTag, DateTime.now()),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final tx in group.items)
          _TransactionTile(
            tx: tx,
            category: categoriesMap[tx.categoryId],
            // ignore: avoid_dynamic_calls
            formatted: fmt.format(tx.amount) as String,
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.category,
    required this.formatted,
  });

  final TransactionModel tx;
  final CategoryModel? category;
  final String formatted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        category != null ? Color(category!.colorValue) : scheme.primary;
    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Hero(
              tag: HeroTags.category(tx.categoryId),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconForCodePoint(
                      category?.iconCodePoint ?? Icons.help_outline.codePoint),
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (tx.notes != null && tx.notes!.isNotEmpty)
                    Text(
                      tx.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isIncome ? '+' : '-'}$formatted',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: tx.isIncome ? scheme.primary : scheme.onSurface,
                  ),
                ),
                if (tx.receiptPath != null && File(tx.receiptPath!).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.receipt,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.receipt_long,
          size: 96,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          l.noTransactions,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l.noTransactionsHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
