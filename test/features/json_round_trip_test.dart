import 'dart:convert';

import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/repositories/transaction_repository.dart';
import 'package:fintrack_app/features/export/json_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('JSON export/import round trip', () {
    test('preserves transactions, categories, and counts', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);

      // Seed data.
      await ctx.db.categories.put(
        'food',
        CategoryModel(
          id: 'food',
          name: 'Food',
          iconCodePoint: 0xe56c,
          colorValue: 0xFFEF5350,
        ),
      );
      final repo = TransactionRepository(ctx.db);
      await repo.create(
        amount: 12.5,
        categoryId: 'food',
        date: DateTime(2026, 5, 6),
        notes: 'lunch',
      );
      await repo.create(
        amount: 1234,
        categoryId: 'food',
        date: DateTime(2026, 5, 7),
        isIncome: true,
      );

      final snapshot = JsonSnapshot(ctx.db).toJsonMap();
      final encoded = jsonEncode(snapshot);

      // Wipe then import.
      await ctx.db.transactions.clear();
      await ctx.db.categories.clear();
      final imported =
          await JsonImporter(ctx.db).importFromString(encoded);
      expect(imported, 2);
      expect(ctx.db.categories.get('food'), isNotNull);
      expect(repo.totalSpentInRange(
        DateTime(2026, 5),
        DateTime(2026, 5, 31),
      ), 12.5);
      expect(repo.totalIncomeInRange(
        DateTime(2026, 5),
        DateTime(2026, 5, 31),
      ), 1234);
    });

    test('rejects future schema version', () async {
      final ctx = await setupSeededDatabase();
      addTearDown(ctx.teardown);
      final json = jsonEncode(<String, dynamic>{
        'schemaVersion': 9999,
        'transactions': <Map<String, dynamic>>[],
        'categories': <Map<String, dynamic>>[],
      });
      expect(
        () => JsonImporter(ctx.db).importFromString(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
