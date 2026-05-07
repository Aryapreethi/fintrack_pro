import 'package:fintrack_app/core/error/app_exceptions.dart';
import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('TransactionRepository', () {
    late TransactionRepository repo;
    late Future<void> Function() teardown;

    setUp(() async {
      final ctx = await setupSeededDatabase();
      repo = TransactionRepository(ctx.db);
      teardown = ctx.teardown;
      // Add a test category beyond the seeded "Uncategorized".
      await ctx.db.categories.put(
        'food',
        CategoryModel(
          id: 'food',
          name: 'Food',
          iconCodePoint: 0xe56c,
          colorValue: 0xFFEF5350,
        ),
      );
    });

    tearDown(() => teardown());

    test('rejects non-positive amounts', () async {
      expect(
        () => repo.create(
          amount: 0,
          categoryId: 'food',
          date: DateTime(2026, 5),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(
          amount: -10,
          categoryId: 'food',
          date: DateTime(2026, 5),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-existent category', () async {
      expect(
        () => repo.create(
          amount: 10,
          categoryId: 'does-not-exist',
          date: DateTime(2026, 5),
        ),
        throwsA(isA<IntegrityException>()),
      );
    });

    test('creates and aggregates by month', () async {
      await repo.create(
        amount: 10,
        categoryId: 'food',
        date: DateTime(2026, 5, 3),
      );
      await repo.create(
        amount: 20.5,
        categoryId: 'food',
        date: DateTime(2026, 5, 25),
      );
      // Different month — should not count.
      await repo.create(
        amount: 999,
        categoryId: 'food',
        date: DateTime(2026, 4, 30),
      );

      final start = DateTime(2026, 5);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      expect(repo.totalSpentInRange(start, end), 30.5);
      expect(repo.spentByCategoryInRange(start, end), {'food': 30.5});
      expect(repo.dailySpendInRange(start, end).length, 2);
    });

    test('income transactions excluded from spent totals', () async {
      await repo.create(
        amount: 100,
        categoryId: 'food',
        date: DateTime(2026, 5),
        isIncome: true,
      );
      await repo.create(
        amount: 25,
        categoryId: 'food',
        date: DateTime(2026, 5),
      );
      final s = DateTime(2026, 5);
      final e = DateTime(2026, 5, 31, 23, 59, 59);
      expect(repo.totalSpentInRange(s, e), 25);
      expect(repo.totalIncomeInRange(s, e), 100);
    });
  });
}
