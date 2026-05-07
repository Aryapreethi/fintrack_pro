import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category_model.dart';
import 'database_providers.dart';

final categoriesStreamProvider =
    StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final categoriesMapProvider =
    Provider<Map<String, CategoryModel>>((ref) {
  final asyncList = ref.watch(categoriesStreamProvider);
  return asyncList.maybeWhen(
    data: (list) => {for (final c in list) c.id: c},
    orElse: () => const {},
  );
});

final expenseCategoriesProvider =
    Provider<List<CategoryModel>>((ref) {
  final asyncList = ref.watch(categoriesStreamProvider);
  return asyncList.maybeWhen(
    data: (list) => list.where((c) => !c.isIncome).toList(),
    orElse: () => const [],
  );
});

final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final asyncList = ref.watch(categoriesStreamProvider);
  return asyncList.maybeWhen(
    data: (list) => list.where((c) => c.isIncome).toList(),
    orElse: () => const [],
  );
});
