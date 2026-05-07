import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/hero_tags.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/budget_providers.dart';
import '../../providers/categories_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/transactions_providers.dart';
import 'widgets/animated_summary_card.dart';
import 'widgets/budget_progress.dart';
import 'widgets/custom_refresh_indicator.dart';
import 'widgets/donut_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider(selectedMonth));
    final breakdown = ref.watch(categoryBreakdownProvider(selectedMonth));
    final categoriesMap = ref.watch(categoriesMapProvider);
    final budget = ref.watch(budgetProgressProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final localeTag = ref.watch(settingsProvider).locale;
    final reducedMotion = ref.watch(reducedMotionProvider);

    final slices = <DonutSliceData>[
      for (var i = 0; i < breakdown.length; i++)
        DonutSliceData(
          id: breakdown[i].categoryId,
          fraction: breakdown[i].fraction,
          label: categoriesMap[breakdown[i].categoryId]?.name ?? 'Unknown',
          color: categoriesMap[breakdown[i].categoryId] != null
              ? Color(categoriesMap[breakdown[i].categoryId]!.colorValue)
              : AppColors.donutPalette[i % AppColors.donutPalette.length],
        ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 380;
    final isWide = width >= 720;
    final horizontalPad = isWide ? 24.0 : 16.0;
    final ringSize = isWide ? 160.0 : (isNarrow ? 110.0 : 140.0);
    final donutHeight = isWide ? 260.0 : (isNarrow ? 180.0 : 220.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabDashboard, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: 'Pick month',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: 'Select month',
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(picked.year, picked.month);
              }
            },
          ),
        ],
      ),
      body: CustomRefresh(
        onRefresh: () async {
          ref.invalidate(transactionsStreamProvider);
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                DateHelpers.formatMonth(selectedMonth, localeTag),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              isNarrow: isNarrow,
              children: [
                AnimatedSummaryCard(
                  label: l.totalSpent,
                  value: summary.totalSpent,
                  formatter: fmt.format,
                  heroTag: HeroTags.summaryTotal,
                  icon: Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  backLabel: 'Net',
                  backValue: summary.net,
                  reducedMotion: reducedMotion,
                ),
                AnimatedSummaryCard(
                  label: l.dailyAverage,
                  value: summary.dailyAverage,
                  formatter: fmt.format,
                  heroTag: HeroTags.summaryDailyAvg,
                  icon: Icons.show_chart,
                  color: Theme.of(context).colorScheme.tertiary,
                  subtitle:
                      'Day ${summary.daysElapsed} / ${summary.daysInMonth}',
                  reducedMotion: reducedMotion,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (budget != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isNarrow
                      ? Column(
                          children: [
                            BudgetRing(
                              fraction: budget.fraction,
                              label: l.budget,
                              value: fmt.formatCompact(budget.remaining),
                              isOver: budget.isOver,
                              size: ringSize,
                              reducedMotion: reducedMotion,
                            ),
                            const SizedBox(height: 12),
                            _BudgetDetails(
                              budget: budget,
                              fmt: fmt,
                              l: l,
                            ),
                          ],
                        )
                      : Row(
                    children: [
                      BudgetRing(
                        fraction: budget.fraction,
                        label: l.budget,
                        value: fmt.formatCompact(budget.remaining),
                        isOver: budget.isOver,
                        size: ringSize,
                        reducedMotion: reducedMotion,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BudgetDetails(
                          budget: budget,
                          fmt: fmt,
                          l: l,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(l.monthlyBudget),
                  subtitle: const Text('Set a monthly limit to track progress'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/budget'),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (isNarrow)
                      Column(
                        children: [
                          SizedBox(
                            height: donutHeight,
                            child: DonutChart(
                              slices: slices,
                              centerLabel: l.totalSpent,
                              centerValue:
                                  fmt.formatCompact(summary.totalSpent),
                              reducedMotion: reducedMotion,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final s in slices)
                            _LegendRow(slice: s),
                        ],
                      )
                    else
                      SizedBox(
                        height: donutHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: DonutChart(
                                slices: slices,
                                centerLabel: l.totalSpent,
                                centerValue:
                                    fmt.formatCompact(summary.totalSpent),
                                reducedMotion: reducedMotion,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: slices.length,
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, i) =>
                                    _LegendRow(slice: slices[i]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (slices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(l.noTransactions,
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l.noTransactionsHint,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.children, required this.isNarrow});

  final List<Widget> children;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _BudgetDetails extends StatelessWidget {
  const _BudgetDetails({
    required this.budget,
    required this.fmt,
    required this.l,
  });

  final BudgetProgress budget;
  final CurrencyFormatter fmt;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.monthlyBudget, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          fmt.format(budget.limit),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          budget.isOver
              ? l.overBudget
              : '${l.remaining}: ${fmt.format(budget.remaining)}',
          style: TextStyle(
            color: budget.isOver
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => context.go('/budget'),
          child: Text(l.edit),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final DonutSliceData slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(
            '${(slice.fraction * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
