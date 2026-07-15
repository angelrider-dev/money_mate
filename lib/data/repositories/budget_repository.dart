import 'package:drift/drift.dart';
import '../local/database.dart';

class BudgetRepository {
  final AppDatabase db;
  BudgetRepository(this.db);

  /// [month] format: "2026-07"
  Stream<List<Budget>> watchForMonth(String month) {
    return (db.select(db.budgets)..where((b) => b.month.equals(month))).watch();
  }

  Future<int> setBudget({
    required int categoryId,
    required double limitAmount,
    required String month,
  }) {
    return db.into(db.budgets).insert(
          BudgetsCompanion.insert(
            categoryId: categoryId,
            limitAmount: limitAmount,
            month: month,
          ),
        );
  }

  Future<void> updateBudget(int id, BudgetsCompanion changes) {
    return (db.update(db.budgets)..where((b) => b.id.equals(id))).write(changes);
  }

  Future<void> deleteBudget(int id) {
    return (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();
  }

  /// Total spent in a category for a given month (from non-deleted expenses).
  Future<double> spentForCategoryInMonth(int categoryId, DateTime monthStart, DateTime monthEnd) async {
    final expenses = await (db.select(db.expenses)
          ..where((e) =>
              e.categoryId.equals(categoryId) &
              e.isDeleted.equals(false) &
              e.date.isBiggerOrEqualValue(monthStart) &
              e.date.isSmallerOrEqualValue(monthEnd)))
        .get();
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Returns the alert level for a spent/limit ratio: null, 'warning' (80%+),
  /// 'danger' (90%+), or 'exceeded' (100%+). Used to color-code progress bars.
  String? alertLevel(double spent, double limit) {
    if (limit <= 0) return null;
    final ratio = spent / limit;
    if (ratio >= 1.0) return 'exceeded';
    if (ratio >= 0.9) return 'danger';
    if (ratio >= 0.8) return 'warning';
    return null;
  }
}
