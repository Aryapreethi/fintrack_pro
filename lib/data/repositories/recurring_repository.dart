import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_exceptions.dart';
import '../datasources/hive_database.dart';
import '../models/frequency.dart';
import '../models/recurring_rule.dart';

class RecurringRepository {
  RecurringRepository(this._db);

  final HiveDatabase _db;
  static const _uuid = Uuid();

  Box<RecurringRule> get _box => _db.recurringRules;

  List<RecurringRule> all() => _box.values.toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  RecurringRule? byId(String id) => _box.get(id);

  Stream<List<RecurringRule>> watchAll() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }

  Future<RecurringRule> create({
    required Frequency frequency,
    required DateTime startDate,
    required double baseAmount,
    required String categoryId,
    DateTime? endDate,
    String? notes,
    bool isIncome = false,
  }) async {
    if (baseAmount <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    if (_db.categories.get(categoryId) == null) {
      throw IntegrityException('Category $categoryId does not exist.');
    }
    final rule = RecurringRule(
      id: _uuid.v4(),
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      baseAmount: baseAmount,
      categoryId: categoryId,
      notes: notes,
      isIncome: isIncome,
      lastGeneratedAt: startDate.subtract(const Duration(days: 1)),
    );
    await _box.put(rule.id, rule);
    return rule;
  }

  Future<void> update(RecurringRule rule) async {
    await _box.put(rule.id, rule);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
