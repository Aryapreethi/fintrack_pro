import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/frequency.dart';
import '../models/recurring_rule.dart';
import '../models/settings_model.dart';
import '../models/transaction_model.dart';

class HiveDatabase {
  HiveDatabase._();
  static final HiveDatabase instance = HiveDatabase._();

  static const String transactionsBoxName = 'transactions';
  static const String categoriesBoxName = 'categories';
  static const String recurringRulesBoxName = 'recurring_rules';
  static const String budgetsBoxName = 'budgets';
  static const String settingsBoxName = 'settings';
  static const String settingsKey = 'app_settings';

  late Box<TransactionModel> transactions;
  late Box<CategoryModel> categories;
  late Box<RecurringRule> recurringRules;
  late Box<BudgetModel> budgets;
  late Box<SettingsModel> settings;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _registerAdapters();
    transactions = await _safeOpen<TransactionModel>(transactionsBoxName);
    categories = await _safeOpen<CategoryModel>(categoriesBoxName);
    recurringRules = await _safeOpen<RecurringRule>(recurringRulesBoxName);
    budgets = await _safeOpen<BudgetModel>(budgetsBoxName);
    settings = await _safeOpen<SettingsModel>(settingsBoxName);
    await _ensureSettings();
    await _seedDefaultCategoriesIfEmpty();
    _initialized = true;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(RecurringRuleAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(FrequencyAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BudgetModelAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SettingsModelAdapter());
  }

  Future<Box<T>> _safeOpen<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Hive box "$name" failed to open: $e — recreating.');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name);
    }
  }

  Future<void> _ensureSettings() async {
    if (settings.get(settingsKey) == null) {
      await settings.put(settingsKey, SettingsModel());
    }
  }

  SettingsModel get currentSettings =>
      settings.get(settingsKey) ?? SettingsModel();

  Future<void> _seedDefaultCategoriesIfEmpty() async {
    if (categories.isNotEmpty) return;
    final defaults = _defaultCategories();
    for (final c in defaults) {
      await categories.put(c.id, c);
    }
  }

  static List<CategoryModel> _defaultCategories() {
    const uuid = Uuid();
    CategoryModel make(String name, IconData icon, Color color,
        {bool isIncome = false, String? fixedId}) {
      return CategoryModel(
        id: fixedId ?? uuid.v4(),
        name: name,
        iconCodePoint: icon.codePoint,
        colorValue: color.toARGB32(),
        isSystem: true,
        isIncome: isIncome,
      );
    }

    return [
      make('Uncategorized', Icons.help_outline, const Color(0xFF9E9E9E),
          fixedId: 'uncategorized'),
      make('Food & Dining', Icons.restaurant, const Color(0xFFEF5350)),
      make('Groceries', Icons.local_grocery_store, const Color(0xFF66BB6A)),
      make('Transport', Icons.directions_bus, const Color(0xFF42A5F5)),
      make('Shopping', Icons.shopping_bag, const Color(0xFFAB47BC)),
      make('Bills & Utilities', Icons.receipt_long, const Color(0xFFFFA726)),
      make('Entertainment', Icons.movie, const Color(0xFFEC407A)),
      make('Health', Icons.favorite, const Color(0xFF26A69A)),
      make('Travel', Icons.flight, const Color(0xFF5C6BC0)),
      make('Education', Icons.school, const Color(0xFF7E57C2)),
      make('Salary', Icons.payments, const Color(0xFF4CAF50), isIncome: true),
      make('Other', Icons.category, const Color(0xFF78909C)),
    ];
  }

  Future<void> clearAll() async {
    await transactions.clear();
    await categories.clear();
    await recurringRules.clear();
    await budgets.clear();
    // Settings preserved by default; caller can clear explicitly.
    await _seedDefaultCategoriesIfEmpty();
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
