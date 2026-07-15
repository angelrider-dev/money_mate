import 'package:drift/drift.dart';
import '../local/database.dart';

class CategoryRepository {
  final AppDatabase db;
  CategoryRepository(this.db);

  /// Live stream of active (non-archived) categories.
  Stream<List<Category>> watchActive() {
    return (db.select(db.categories)..where((c) => c.isArchived.equals(false)))
        .watch();
  }

  Future<int> addCategory({
    required String name,
    required String icon,
    required String colorHex,
  }) {
    return db.into(db.categories).insert(
          CategoriesCompanion.insert(name: name, icon: icon, colorHex: colorHex),
        );
  }

  Future<void> updateCategory(int id, CategoriesCompanion changes) {
    return (db.update(db.categories)..where((c) => c.id.equals(id))).write(changes);
  }

  /// Checks if any non-deleted expense still references this category.
  Future<bool> isInUse(int categoryId) async {
    final count = await (db.select(db.expenses)
          ..where((e) => e.categoryId.equals(categoryId) & e.isDeleted.equals(false)))
        .get();
    return count.isNotEmpty;
  }

  /// Archives the category (never hard-deletes) — safe even if in use,
  /// since archived categories just stop appearing in pickers for new expenses
  /// while existing expenses keep referencing them correctly.
  Future<void> archive(int id) {
    return updateCategory(id, const CategoriesCompanion(isArchived: Value(true)));
  }

  Future<void> unarchive(int id) {
    return updateCategory(id, const CategoriesCompanion(isArchived: Value(false)));
  }
}
