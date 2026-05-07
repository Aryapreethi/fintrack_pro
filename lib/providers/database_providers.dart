import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/hive_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../services/repair_service.dart';

final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase.instance;
});

final databaseInitProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(hiveDatabaseProvider);
  await db.init();
  await RepairService(db).run();
});

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(hiveDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(hiveDatabaseProvider));
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(hiveDatabaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(hiveDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(hiveDatabaseProvider));
});
