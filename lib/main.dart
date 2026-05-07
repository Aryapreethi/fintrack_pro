import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/datasources/hive_database.dart';
import 'data/repositories/recurring_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/recurring/recurring_engine.dart';
import 'services/repair_service.dart';
import 'services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await HiveDatabase.instance.init();
  await RepairService(HiveDatabase.instance).run();

  final db = HiveDatabase.instance;
  await RecurringEngine(
    recurringRepo: RecurringRepository(db),
    transactionRepo: TransactionRepository(db),
  ).materializeDue();

  if (!kIsWeb && Platform.isAndroid) {
    try {
      await WorkManagerService().init();
    } catch (e) {
      debugPrint('WorkManager init failed (non-fatal): $e');
    }
  }

  runApp(const ProviderScope(child: FintrackApp()));
}
