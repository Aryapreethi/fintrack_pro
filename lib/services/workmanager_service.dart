import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../data/datasources/hive_database.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../features/recurring/recurring_engine.dart';

const String _recurringTaskName = 'fintrack.recurring.materialize';
const String _recurringTaskUniqueName = 'fintrack-recurring-daily';

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _recurringTaskName) return true;
    try {
      // Re-init Hive in the background isolate.
      await HiveDatabase.instance.init();
      final db = HiveDatabase.instance;
      final engine = RecurringEngine(
        recurringRepo: RecurringRepository(db),
        transactionRepo: TransactionRepository(db),
      );
      final created = await engine.materializeDue();
      debugPrint('[BG] recurring materialized: $created');
      return true;
    } catch (e, st) {
      debugPrint('[BG] recurring task failed: $e\n$st');
      return false;
    }
  });
}

class WorkManagerService {
  Future<void> init() async {
    await Workmanager().initialize(
      workmanagerCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    await Workmanager().registerPeriodicTask(
      _recurringTaskUniqueName,
      _recurringTaskName,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  Future<void> cancel() => Workmanager().cancelAll();
}
