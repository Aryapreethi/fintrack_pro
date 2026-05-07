import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_exceptions.dart';
import '../datasources/hive_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final HiveDatabase _db;
  static const _uuid = Uuid();

  Box<CategoryModel> get _box => _db.categories;

  List<CategoryModel> all() {
    final list = _box.values.toList()
      ..sort((a, b) {
        if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  List<CategoryModel> expenseCategories() =>
      all().where((c) => !c.isIncome).toList();

  List<CategoryModel> incomeCategories() =>
      all().where((c) => c.isIncome).toList();

  CategoryModel? byId(String id) => _box.get(id);

  Stream<List<CategoryModel>> watchAll() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }

  Future<CategoryModel> create({
    required String name,
    required int iconCodePoint,
    required int colorValue,
    bool isIncome = false,
  }) async {
    if (name.trim().isEmpty) {
      throw ValidationException('Category name is required.');
    }
    final cat = CategoryModel(
      id: _uuid.v4(),
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isIncome: isIncome,
    );
    await _box.put(cat.id, cat);
    return cat;
  }

  Future<void> update(CategoryModel cat) async {
    if (cat.name.trim().isEmpty) {
      throw ValidationException('Category name is required.');
    }
    await _box.put(cat.id, cat);
  }

  Future<void> delete(String id) async {
    final cat = _box.get(id);
    if (cat == null) return;
    if (cat.isSystem) {
      throw ValidationException('System categories cannot be deleted.');
    }
    // Reassign affected transactions to Uncategorized.
    for (final tx in _db.transactions.values
        .where((t) => t.categoryId == id)
        .toList()) {
      tx.categoryId = 'uncategorized';
      tx.updatedAt = DateTime.now();
      await tx.save();
    }
    await _box.delete(id);
  }
}
