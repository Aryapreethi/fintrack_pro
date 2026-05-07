import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/hive_database.dart';

class CsvExporter {
  CsvExporter(this.db);
  final HiveDatabase db;

  Future<File> exportTransactions({String localeTag = 'en'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${exportsDir.path}/fintrack-transactions-$stamp.csv');

    final dateFmt = DateFormat.yMd(localeTag);
    final categories = {for (final c in db.categories.values) c.id: c.name};

    final buffer = StringBuffer()
      ..writeln('Date,Category,Amount,Type,Notes,Recurring');
    for (final t in db.transactions.values) {
      final cat = categories[t.categoryId] ?? '';
      final type = t.isIncome ? 'Income' : 'Expense';
      final notes = (t.notes ?? '').replaceAll('"', '""');
      buffer
        ..write('${dateFmt.format(t.date)},')
        ..write('${_escape(cat)},')
        ..write('${t.amount.toStringAsFixed(2)},')
        ..write('$type,')
        ..write('${_escape(notes)},')
        ..writeln(t.recurringRuleId != null ? 'yes' : 'no');
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
