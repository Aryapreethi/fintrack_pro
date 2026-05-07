import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_exceptions.dart';
import '../datasources/hive_database.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._db);

  final HiveDatabase _db;
  static const _uuid = Uuid();

  Box<TransactionModel> get _box => _db.transactions;

  List<TransactionModel> all() {
    final list = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  TransactionModel? byId(String id) => _box.get(id);

  Stream<List<TransactionModel>> watchAll() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }

  List<TransactionModel> inRange(DateTime start, DateTime end) {
    return _box.values
        .where(
          (t) =>
              !t.date.isBefore(start) &&
              !t.date.isAfter(end),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<TransactionModel> create({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? notes,
    String? receiptPath,
    String? recurringRuleId,
    bool isIncome = false,
  }) async {
    if (amount <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    if (_db.categories.get(categoryId) == null) {
      throw IntegrityException('Category $categoryId does not exist.');
    }
    final now = DateTime.now();
    final tx = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      notes: notes,
      receiptPath: receiptPath,
      recurringRuleId: recurringRuleId,
      isIncome: isIncome,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(tx.id, tx);
    return tx;
  }

  Future<void> update(TransactionModel tx) async {
    if (tx.amount <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    if (_db.categories.get(tx.categoryId) == null) {
      throw IntegrityException('Category ${tx.categoryId} does not exist.');
    }
    tx.updatedAt = DateTime.now();
    await _box.put(tx.id, tx);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() => _box.clear();

  /// Aggregations
  double totalSpentInRange(DateTime start, DateTime end) {
    return inRange(start, end)
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double totalIncomeInRange(DateTime start, DateTime end) {
    return inRange(start, end)
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> spentByCategoryInRange(DateTime start, DateTime end) {
    final out = <String, double>{};
    for (final t in inRange(start, end)) {
      if (t.isIncome) continue;
      out.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return out;
  }

  Map<DateTime, double> dailySpendInRange(DateTime start, DateTime end) {
    final out = <DateTime, double>{};
    for (final t in inRange(start, end)) {
      if (t.isIncome) continue;
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      out.update(key, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return out;
  }
}
