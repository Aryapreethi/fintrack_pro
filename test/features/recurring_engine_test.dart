import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/models/frequency.dart';
import 'package:fintrack_app/data/repositories/recurring_repository.dart';
import 'package:fintrack_app/data/repositories/transaction_repository.dart';
import 'package:fintrack_app/features/recurring/recurring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('RecurringEngine', () {
    late RecurringRepository recurringRepo;
    late TransactionRepository txRepo;
    late Future<void> Function() teardown;

    setUp(() async {
      final ctx = await setupSeededDatabase();
      await ctx.db.categories.put(
        'subs',
        CategoryModel(
          id: 'subs',
          name: 'Subscriptions',
          iconCodePoint: 0xe333,
          colorValue: 0xFF42A5F5,
        ),
      );
      recurringRepo = RecurringRepository(ctx.db);
      txRepo = TransactionRepository(ctx.db);
      teardown = ctx.teardown;
    });

    tearDown(() => teardown());

    test('daily rule materializes one transaction per day', () async {
      final now = DateTime(2026, 5, 7, 12);
      final start = DateTime(2026, 5, 4, 12);
      await recurringRepo.create(
        frequency: Frequency.daily,
        startDate: start,
        baseAmount: 5,
        categoryId: 'subs',
      );
      final engine = RecurringEngine(
        recurringRepo: recurringRepo,
        transactionRepo: txRepo,
        clock: () => now,
      );
      final created = await engine.materializeDue();
      // Expected occurrences after start: 5/4, 5/5, 5/6, 5/7 → first occurrence
      // is _nextOccurrenceAfter(start - 1day) = start, so we expect 4.
      expect(created, 4);
      expect(txRepo.all().length, 4);
    });

    test('engine is idempotent across multiple invocations', () async {
      final now = DateTime(2026, 5, 7, 12);
      await recurringRepo.create(
        frequency: Frequency.weekly,
        startDate: DateTime(2026, 4, 23, 12),
        baseAmount: 50,
        categoryId: 'subs',
      );
      final engine = RecurringEngine(
        recurringRepo: recurringRepo,
        transactionRepo: txRepo,
        clock: () => now,
      );
      final first = await engine.materializeDue();
      final second = await engine.materializeDue();
      expect(first, greaterThan(0));
      expect(second, 0); // already materialized
    });

    test('monthly rule respects end date', () async {
      final start = DateTime(2026, 1, 15);
      final end = DateTime(2026, 3, 16);
      final now = DateTime(2026, 12);
      await recurringRepo.create(
        frequency: Frequency.monthly,
        startDate: start,
        endDate: end,
        baseAmount: 100,
        categoryId: 'subs',
      );
      final engine = RecurringEngine(
        recurringRepo: recurringRepo,
        transactionRepo: txRepo,
        clock: () => now,
      );
      final created = await engine.materializeDue();
      expect(created, 3); // Jan 15, Feb 15, Mar 15
    });
  });
}
