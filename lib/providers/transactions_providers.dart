import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_helpers.dart';
import '../data/models/transaction_model.dart';
import 'database_providers.dart';

final transactionsStreamProvider =
    StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAll();
});

class MonthlySummary {
  const MonthlySummary({
    required this.totalSpent,
    required this.totalIncome,
    required this.dailyAverage,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.month,
  });

  final double totalSpent;
  final double totalIncome;
  final double dailyAverage;
  final int daysElapsed;
  final int daysInMonth;
  final DateTime month;

  double get net => totalIncome - totalSpent;
}

class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.amount,
    required this.fraction,
  });

  final String categoryId;
  final double amount;
  final double fraction;
}

final monthlySummaryProvider =
    Provider.family<MonthlySummary, DateTime>((ref, monthAnchor) {
  // Trigger recomputation when transactions change.
  ref.watch(transactionsStreamProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final start = DateHelpers.startOfMonth(monthAnchor);
  final end = DateHelpers.endOfMonth(monthAnchor);
  final spent = repo.totalSpentInRange(start, end);
  final income = repo.totalIncomeInRange(start, end);
  final now = DateTime.now();
  final daysInMonth = DateHelpers.daysInMonth(monthAnchor);
  final daysElapsed = (monthAnchor.year == now.year &&
          monthAnchor.month == now.month)
      ? now.day
      : daysInMonth;
  final dailyAvg = daysElapsed == 0 ? 0.0 : spent / daysElapsed;

  return MonthlySummary(
    totalSpent: spent,
    totalIncome: income,
    dailyAverage: dailyAvg,
    daysElapsed: daysElapsed,
    daysInMonth: daysInMonth,
    month: DateHelpers.startOfMonth(monthAnchor),
  );
});

final categoryBreakdownProvider =
    Provider.family<List<CategorySlice>, DateTime>((ref, monthAnchor) {
  ref.watch(transactionsStreamProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final start = DateHelpers.startOfMonth(monthAnchor);
  final end = DateHelpers.endOfMonth(monthAnchor);
  final byCategory = repo.spentByCategoryInRange(start, end);
  final total = byCategory.values.fold<double>(0, (s, v) => s + v);
  if (total == 0) return const [];
  final slices = byCategory.entries
      .map(
        (e) => CategorySlice(
          categoryId: e.key,
          amount: e.value,
          fraction: e.value / total,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
