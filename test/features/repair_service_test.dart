import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/models/transaction_model.dart';
import 'package:fintrack_app/services/repair_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('RepairService', () {
    test('reassigns orphaned transactions to Uncategorized', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);

      final now = DateTime.now();
      // Insert a transaction with an unknown category id.
      await ctx.db.transactions.put(
        'tx1',
        TransactionModel(
          id: 'tx1',
          amount: 5,
          categoryId: 'gone',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final report = await RepairService(ctx.db).run();
      expect(report.orphanedTransactionsReassigned, 1);
      expect(ctx.db.transactions.get('tx1')!.categoryId, 'uncategorized');
    });

    test('clears receipt path when file is missing', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);

      final now = DateTime.now();
      await ctx.db.transactions.put(
        'tx-receipt',
        TransactionModel(
          id: 'tx-receipt',
          amount: 5,
          categoryId: 'uncategorized',
          date: now,
          receiptPath: '/no/such/file.jpg',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final report = await RepairService(ctx.db).run();
      expect(report.missingReceiptsCleared, 1);
      expect(
        ctx.db.transactions.get('tx-receipt')!.receiptPath,
        isNull,
      );
    });

    test('deduplicates non-system categories by name', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);

      await ctx.db.categories.put(
        'a',
        CategoryModel(
          id: 'a',
          name: 'Coffee',
          iconCodePoint: 0xe338,
          colorValue: 0xFF000000,
        ),
      );
      await ctx.db.categories.put(
        'b',
        CategoryModel(
          id: 'b',
          name: 'coffee', // case-insensitive duplicate
          iconCodePoint: 0xe338,
          colorValue: 0xFF000000,
        ),
      );
      final report = await RepairService(ctx.db).run();
      expect(report.duplicateCategoriesRemoved, 1);
      expect(ctx.db.categories.length, 2); // uncategorized + a
    });
  });
}
