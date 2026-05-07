import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/datasources/hive_database.dart';

class RepairReport {
  RepairReport({
    this.orphanedTransactionsReassigned = 0,
    this.missingReceiptsCleared = 0,
    this.duplicateCategoriesRemoved = 0,
  });

  int orphanedTransactionsReassigned;
  int missingReceiptsCleared;
  int duplicateCategoriesRemoved;

  bool get touchedAnything =>
      orphanedTransactionsReassigned > 0 ||
      missingReceiptsCleared > 0 ||
      duplicateCategoriesRemoved > 0;

  @override
  String toString() =>
      'RepairReport(orphans=$orphanedTransactionsReassigned, '
      'receipts=$missingReceiptsCleared, '
      'dupes=$duplicateCategoriesRemoved)';
}

class RepairService {
  RepairService(this._db);

  final HiveDatabase _db;

  static const String _uncategorizedId = 'uncategorized';

  Future<RepairReport> run() async {
    final report = RepairReport();
    await _reassignOrphanTransactions(report);
    await _clearMissingReceipts(report);
    await _deduplicateCategories(report);
    if (report.touchedAnything) {
      debugPrint('RepairService: $report');
    }
    return report;
  }

  Future<void> _reassignOrphanTransactions(RepairReport report) async {
    final categoryIds = _db.categories.keys.cast<String>().toSet();
    for (final tx in _db.transactions.values.toList()) {
      if (!categoryIds.contains(tx.categoryId)) {
        tx.categoryId = _uncategorizedId;
        tx.updatedAt = DateTime.now();
        await tx.save();
        report.orphanedTransactionsReassigned++;
      }
    }
  }

  Future<void> _clearMissingReceipts(RepairReport report) async {
    for (final tx in _db.transactions.values.toList()) {
      final path = tx.receiptPath;
      if (path == null) continue;
      if (!File(path).existsSync()) {
        tx.receiptPath = null;
        tx.updatedAt = DateTime.now();
        await tx.save();
        report.missingReceiptsCleared++;
      }
    }
  }

  Future<void> _deduplicateCategories(RepairReport report) async {
    final seenNames = <String, String>{};
    for (final cat in _db.categories.values.toList()) {
      final norm = cat.name.trim().toLowerCase();
      final firstId = seenNames[norm];
      if (firstId == null) {
        seenNames[norm] = cat.id;
        continue;
      }
      // Reassign txns from this duplicate to the canonical id, then drop it.
      for (final tx in _db.transactions.values
          .where((t) => t.categoryId == cat.id)
          .toList()) {
        tx.categoryId = firstId;
        tx.updatedAt = DateTime.now();
        await tx.save();
      }
      if (!cat.isSystem) {
        await cat.delete();
        report.duplicateCategoriesRemoved++;
      }
    }
  }
}
