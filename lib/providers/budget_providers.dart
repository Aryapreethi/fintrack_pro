import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/budget_model.dart';
import 'database_providers.dart';
import 'transactions_providers.dart';

final activeBudgetProvider = StreamProvider<BudgetModel?>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchActive();
});

class BudgetProgress {
  const BudgetProgress({
    required this.spent,
    required this.limit,
    required this.fraction,
    required this.isOver,
  });

  final double spent;
  final double limit;
  final double fraction;
  final bool isOver;

  double get remaining => (limit - spent).clamp(0, double.infinity);
}

final budgetProgressProvider = Provider<BudgetProgress?>((ref) {
  final budget = ref.watch(activeBudgetProvider).maybeWhen(
        data: (v) => v,
        orElse: () => null,
      );
  if (budget == null) return null;
  final selected = ref.watch(selectedMonthProvider);
  final summary = ref.watch(monthlySummaryProvider(selected));
  final fraction = budget.monthlyLimit == 0
      ? 0.0
      : (summary.totalSpent / budget.monthlyLimit);
  return BudgetProgress(
    spent: summary.totalSpent,
    limit: budget.monthlyLimit,
    fraction: fraction.clamp(0.0, 1.0).toDouble(),
    isOver: summary.totalSpent > budget.monthlyLimit,
  );
});
