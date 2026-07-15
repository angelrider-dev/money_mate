import 'package:drift/drift.dart';
import '../local/database.dart';

/// All access to the Expenses table goes through this repository.
/// UI/providers never call `db.select(db.expenses)` directly.
class ExpenseRepository {
  final AppDatabase db;
  ExpenseRepository(this.db);

  /// Live stream of non-deleted expenses, newest first.
  Stream<List<Expense>> watchAll() {
    return (db.select(db.expenses)
          ..where((e) => e.isDeleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Live stream of expenses within a date range (for list filters, dashboards).
  Stream<List<Expense>> watchByDateRange(DateTime start, DateTime end) {
    return (db.select(db.expenses)
          ..where((e) =>
              e.isDeleted.equals(false) &
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerOrEqualValue(end))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Live stream of expenses for a specific category.
  Stream<List<Expense>> watchByCategory(int categoryId) {
    return (db.select(db.expenses)
          ..where((e) => e.isDeleted.equals(false) & e.categoryId.equals(categoryId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Expenses still needing review (added via Quick Add, not yet completed).
  Stream<List<Expense>> watchNeedsReview() {
    return (db.select(db.expenses)
          ..where((e) => e.isDeleted.equals(false) & e.needsReview.equals(true))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Full "Add Expense" form save.
  Future<int> addExpense({
    required double amount,
    required String title,
    int? categoryId,
    required DateTime date,
    String? note,
    String? receiptPath,
    int? groupId,
    int? paidByMemberId,
    String splitType = 'equal',
    int? accountId,
    int? recurringRuleId,
    bool needsReview = false,
  }) {
    return db.into(db.expenses).insert(
          ExpensesCompanion.insert(
            title: title,
            amount: amount,
            categoryId: Value(categoryId),
            date: date,
            note: Value(note),
            receiptPath: Value(receiptPath),
            groupId: Value(groupId),
            paidByMemberId: Value(paidByMemberId),
            splitType: Value(splitType),
            accountId: Value(accountId),
            recurringRuleId: Value(recurringRuleId),
            needsReview: Value(needsReview),
          ),
        );
  }

  /// Quick Add — amount-only or photo-only save. Category left null,
  /// needsReview set true so it surfaces in the "X expenses need review" list.
  Future<int> quickAdd({
    required double amount,
    String? receiptPath,
  }) {
    return addExpense(
      amount: amount,
      title: 'Quick Expense',
      date: DateTime.now(),
      receiptPath: receiptPath,
      needsReview: true,
    );
  }

  Future<void> updateExpense(int id, ExpensesCompanion changes) {
    return (db.update(db.expenses)..where((e) => e.id.equals(id))).write(changes);
  }

  /// Marks the expense as reviewed/completed (clears the Quick Add flag).
  Future<void> markReviewed(int id) {
    return updateExpense(id, const ExpensesCompanion(needsReview: Value(false)));
  }

  /// Soft delete — never removes the row. Powers the Undo snackbar.
  Future<void> softDelete(int id) {
    return updateExpense(
      id,
      ExpensesCompanion(isDeleted: const Value(true), deletedAt: Value(DateTime.now())),
    );
  }

  /// Undo a soft delete within the snackbar window.
  Future<void> undoDelete(int id) {
    return updateExpense(
      id,
      const ExpensesCompanion(isDeleted: Value(false), deletedAt: Value(null)),
    );
  }
}
