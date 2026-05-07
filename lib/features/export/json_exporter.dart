import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/datasources/hive_database.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction_model.dart';

class JsonSnapshot {
  static const int schemaVersion = 1;

  final HiveDatabase db;
  JsonSnapshot(this.db);

  Map<String, dynamic> toJsonMap() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': [
        for (final t in db.transactions.values) t.toJson(),
      ],
      'categories': [
        for (final c in db.categories.values) c.toJson(),
      ],
      'recurringRules': [
        for (final r in db.recurringRules.values) r.toJson(),
      ],
      'budgets': [
        for (final b in db.budgets.values) b.toJson(),
      ],
      'settings': db.currentSettings.toJson(),
    };
  }

  Future<File> writeToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${exportsDir.path}/fintrack-$stamp.json');
    final json = const JsonEncoder.withIndent('  ').convert(toJsonMap());
    await file.writeAsString(json);
    return file;
  }
}

class JsonImporter {
  JsonImporter(this.db);
  final HiveDatabase db;

  Future<int> importFromString(String content) async {
    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file: not a JSON object.');
    }
    final version = decoded['schemaVersion'];
    if (version is! int || version > JsonSnapshot.schemaVersion) {
      throw FormatException(
        'Unsupported backup schema version: $version',
      );
    }

    var imported = 0;

    // Replace categories first so transactions can validate FK.
    await db.categories.clear();
    for (final raw in (decoded['categories'] as List? ?? [])) {
      final c = CategoryModel.fromJson(raw as Map<String, dynamic>);
      await db.categories.put(c.id, c);
    }

    await db.budgets.clear();
    for (final raw in (decoded['budgets'] as List? ?? [])) {
      final b = BudgetModel.fromJson(raw as Map<String, dynamic>);
      await db.budgets.put(b.id, b);
    }

    await db.recurringRules.clear();
    for (final raw in (decoded['recurringRules'] as List? ?? [])) {
      final r = RecurringRule.fromJson(raw as Map<String, dynamic>);
      await db.recurringRules.put(r.id, r);
    }

    await db.transactions.clear();
    for (final raw in (decoded['transactions'] as List? ?? [])) {
      final t = TransactionModel.fromJson(raw as Map<String, dynamic>);
      await db.transactions.put(t.id, t);
      imported++;
    }

    return imported;
  }
}
