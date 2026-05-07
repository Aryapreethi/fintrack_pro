import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/recurring_rule.dart';
import 'database_providers.dart';

final recurringRulesStreamProvider =
    StreamProvider<List<RecurringRule>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchAll();
});
