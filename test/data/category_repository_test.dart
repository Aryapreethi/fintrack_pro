import 'package:fintrack_app/core/error/app_exceptions.dart';
import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/repositories/category_repository.dart';
import 'package:fintrack_app/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('CategoryRepository', () {
    test('rejects empty names', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);
      final repo = CategoryRepository(ctx.db);
      expect(
        () => repo.create(
          name: '   ',
          iconCodePoint: 0xe148,
          colorValue: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses to delete system categories', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);
      final repo = CategoryRepository(ctx.db);
      expect(
        () => repo.delete('uncategorized'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('reassigns transactions when a category is deleted', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);

      await ctx.db.categories.put(
        'gym',
        CategoryModel(
          id: 'gym',
          name: 'Gym',
          iconCodePoint: 0xe57e,
          colorValue: 0,
        ),
      );
      final txRepo = TransactionRepository(ctx.db);
      await txRepo.create(
        amount: 50,
        categoryId: 'gym',
        date: DateTime(2026, 5),
      );

      final catRepo = CategoryRepository(ctx.db);
      await catRepo.delete('gym');
      expect(ctx.db.categories.get('gym'), isNull);
      final remainingTx = ctx.db.transactions.values.first;
      expect(remainingTx.categoryId, 'uncategorized');
    });
  });
}
