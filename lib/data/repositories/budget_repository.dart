import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../datasources/hive_database.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  BudgetRepository(this._db);

  final HiveDatabase _db;
  static const _uuid = Uuid();
  static const String _activeKey = 'active_budget';

  Box<BudgetModel> get _box => _db.budgets;

  BudgetModel? active() => _box.get(_activeKey);

  Stream<BudgetModel?> watchActive() async* {
    yield active();
    yield* _box.watch(key: _activeKey).map((_) => active());
  }

  Future<BudgetModel> setActive({
    required double monthlyLimit,
    required String currency,
  }) async {
    final now = DateTime.now();
    final existing = active();
    final budget = BudgetModel(
      id: existing?.id ?? _uuid.v4(),
      monthlyLimit: monthlyLimit,
      currency: currency,
      periodStart: DateTime(now.year, now.month),
    );
    await _box.put(_activeKey, budget);
    return budget;
  }

  Future<void> clear() => _box.delete(_activeKey);
}
