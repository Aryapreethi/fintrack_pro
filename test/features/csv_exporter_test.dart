import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/repositories/transaction_repository.dart';
import 'package:fintrack_app/features/export/csv_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  test('CsvExporter writes header and one row per transaction', () async {
    final ctx = await setupSeededDatabase();
    addTearDown(ctx.teardown);

    await ctx.db.categories.put(
      'food',
      CategoryModel(
        id: 'food',
        name: 'Food, & Dining',
        iconCodePoint: 0xe56c,
        colorValue: 0xFFEF5350,
      ),
    );
    final repo = TransactionRepository(ctx.db);
    await repo.create(
      amount: 5.5,
      categoryId: 'food',
      date: DateTime(2026, 5),
      notes: 'with "quotes" and, comma',
    );

    final file = await CsvExporter(ctx.db).exportTransactions();
    final text = await file.readAsString();
    expect(text.startsWith('Date,Category,Amount,Type,Notes,Recurring'), isTrue);
    expect(text.contains('"Food, & Dining"'), isTrue);
    // Quote escaping: single inner double-quote becomes a doubled quote.
    expect(text.contains('""quotes""'), isTrue);
  });
}
