import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fintrack_app/data/datasources/hive_database.dart';
import 'package:fintrack_app/data/models/budget_model.dart';
import 'package:fintrack_app/data/models/category_model.dart';
import 'package:fintrack_app/data/models/frequency.dart';
import 'package:fintrack_app/data/models/recurring_rule.dart';
import 'package:fintrack_app/data/models/settings_model.dart';
import 'package:fintrack_app/data/models/transaction_model.dart';

/// Spins up a fresh Hive in a temp directory and registers all adapters.
/// Returns a function that closes Hive and deletes the temp dir.
Future<void Function()> setupTestHive() async {
  TestWidgetsFlutterBindingInitializer.ensure();
  final tmp = await Directory.systemTemp.createTemp('fintrack_test_');
  Hive.init(tmp.path);
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(RecurringRuleAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(FrequencyAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BudgetModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SettingsModelAdapter());

  return () async {
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  };
}

class TestWidgetsFlutterBindingInitializer {
  static void ensure() {
    // For unit tests, ensures binary messengers, etc., are wired.
    // Most simple unit tests don't need this, but mocked plugins do.
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}

/// Boots a fully-seeded HiveDatabase with default categories. Returns the db
/// and a teardown function. Uses a temp directory for isolation.
Future<({HiveDatabase db, Future<void> Function() teardown})>
    setupSeededDatabase() async {
  final teardownHive = await setupTestHive();
  final db = HiveDatabase.instance;
  // Open boxes manually using the same names since HiveDatabase.init() calls
  // Hive.initFlutter which conflicts with Hive.init in tests.
  db.transactions = await Hive.openBox<TransactionModel>(
    HiveDatabase.transactionsBoxName,
  );
  db.categories = await Hive.openBox<CategoryModel>(
    HiveDatabase.categoriesBoxName,
  );
  db.recurringRules = await Hive.openBox<RecurringRule>(
    HiveDatabase.recurringRulesBoxName,
  );
  db.budgets = await Hive.openBox<BudgetModel>(HiveDatabase.budgetsBoxName);
  db.settings = await Hive.openBox<SettingsModel>(
    HiveDatabase.settingsBoxName,
  );
  if (db.settings.get(HiveDatabase.settingsKey) == null) {
    await db.settings.put(HiveDatabase.settingsKey, SettingsModel());
  }
  // Seed an Uncategorized category to mirror production seed.
  if (db.categories.get('uncategorized') == null) {
    await db.categories.put(
      'uncategorized',
      CategoryModel(
        id: 'uncategorized',
        name: 'Uncategorized',
        iconCodePoint: 0xe148,
        colorValue: 0xFF9E9E9E,
        isSystem: true,
      ),
    );
  }
  return (
    db: db,
    teardown: () async {
      await db.transactions.clear();
      await db.categories.clear();
      await db.recurringRules.clear();
      await db.budgets.clear();
      await db.settings.clear();
      teardownHive();
    },
  );
}
