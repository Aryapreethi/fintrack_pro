import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/utils/currency_formatter.dart';
import '../core/utils/date_helpers.dart';
import '../data/datasources/hive_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/transaction_repository.dart';

class HomeWidgetService {
  HomeWidgetService(this.db);
  final HiveDatabase db;

  static const String _androidProvider = 'FintrackWidgetProvider';
  static const String _iosName = 'FintrackWidget';

  Future<void> updateAll() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final settings = db.currentSettings;
      final fmt = CurrencyFormatter(
        localeTag: settings.locale,
        currencyCode: settings.currencyCode,
      );
      final txRepo = TransactionRepository(db);
      final budgetRepo = BudgetRepository(db);
      final now = DateTime.now();
      final start = DateHelpers.startOfMonth(now);
      final end = DateHelpers.endOfMonth(now);
      final spent = txRepo.totalSpentInRange(start, end);
      final budget = budgetRepo.active();
      final remaining =
          budget == null ? null : (budget.monthlyLimit - spent);

      await HomeWidget.saveWidgetData<String>(
        'fintrack_total_spent',
        fmt.formatCompact(spent),
      );
      await HomeWidget.saveWidgetData<String>(
        'fintrack_remaining',
        remaining == null ? '—' : fmt.formatCompact(remaining),
      );
      await HomeWidget.saveWidgetData<String>(
        'fintrack_period',
        DateHelpers.formatMonth(now, settings.locale),
      );
      await HomeWidget.updateWidget(
        androidName: _androidProvider,
        iOSName: _iosName,
      );
    } catch (e) {
      debugPrint('Home widget update failed: $e');
    }
  }
}
