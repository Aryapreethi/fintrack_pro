import '../../data/models/frequency.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/transaction_repository.dart';

/// Materializes due transactions for active recurring rules.
/// Idempotent: safe to invoke multiple times — uses [RecurringRule.lastGeneratedAt].
class RecurringEngine {
  RecurringEngine({
    required this.recurringRepo,
    required this.transactionRepo,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final RecurringRepository recurringRepo;
  final TransactionRepository transactionRepo;
  final DateTime Function() _now;

  /// Generates instances up to (and including) "now" for every active rule.
  /// Returns the number of transactions created.
  Future<int> materializeDue() async {
    final now = _now();
    var created = 0;
    for (final rule in recurringRepo.all()) {
      created += await _materializeRule(rule, now);
    }
    return created;
  }

  Future<int> _materializeRule(RecurringRule rule, DateTime now) async {
    if (rule.endDate != null && now.isAfter(rule.endDate!)) return 0;
    final endTarget =
        rule.endDate != null && rule.endDate!.isBefore(now) ? rule.endDate! : now;

    var cursor = _nextOccurrenceAfter(rule.lastGeneratedAt, rule);
    var count = 0;
    while (!cursor.isAfter(endTarget)) {
      await transactionRepo.create(
        amount: rule.baseAmount,
        categoryId: rule.categoryId,
        date: cursor,
        notes: rule.notes,
        recurringRuleId: rule.id,
        isIncome: rule.isIncome,
      );
      count++;
      rule.lastGeneratedAt = cursor;
      await rule.save();
      cursor = _nextOccurrenceAfter(cursor, rule);
    }
    return count;
  }

  DateTime _nextOccurrenceAfter(DateTime from, RecurringRule rule) {
    switch (rule.frequency) {
      case Frequency.daily:
        return from.add(const Duration(days: 1));
      case Frequency.weekly:
        return from.add(const Duration(days: 7));
      case Frequency.monthly:
        final m = from.month + 1;
        final year = from.year + (m > 12 ? 1 : 0);
        final month = m > 12 ? 1 : m;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = from.day > lastDay ? lastDay : from.day;
        return DateTime(year, month, day, from.hour, from.minute);
    }
  }
}
