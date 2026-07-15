import 'package:drift/drift.dart';
import '../local/database.dart';
import 'expense_repository.dart';
import 'income_repository.dart';

class RecurringRuleRepository {
  final AppDatabase db;
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  RecurringRuleRepository(this.db, this.expenseRepository, this.incomeRepository);

  Stream<List<RecurringRule>> watchActiveRules() {
    return (db.select(db.recurringRules)..where((r) => r.isActive.equals(true))).watch();
  }

  Future<int> createRule({
    required String title,
    required double amount,
    required String type, // 'expense' | 'income'
    int? categoryId,
    int? sourceId,
    required String frequency, // 'daily' | 'weekly' | 'monthly' | 'yearly'
    required DateTime nextDueDate,
    DateTime? endDate,
    bool autoCreate = true,
  }) {
    return db.into(db.recurringRules).insert(
          RecurringRulesCompanion.insert(
            title: title,
            amount: amount,
            type: type,
            categoryId: Value(categoryId),
            sourceId: Value(sourceId),
            frequency: frequency,
            nextDueDate: nextDueDate,
            endDate: Value(endDate),
            autoCreate: Value(autoCreate),
          ),
        );
  }

  Future<void> updateRule(int id, RecurringRulesCompanion changes) {
    return (db.update(db.recurringRules)..where((r) => r.id.equals(id))).write(changes);
  }

  Future<void> deactivateRule(int id) {
    return updateRule(id, const RecurringRulesCompanion(isActive: Value(false)));
  }

  DateTime _advance(DateTime date, String frequency) {
    switch (frequency) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(date.year, date.month + 1, date.day);
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 30));
    }
  }

  /// Call this once when the app opens. For every active rule whose
  /// nextDueDate has passed, creates the missed transaction(s) and advances
  /// nextDueDate forward.
  ///
  /// DECISION: catch-up creates EVERY missed occurrence (capped at 12, to
  /// avoid a runaway loop if a rule was left active for years) rather than
  /// just the latest one — this keeps the expense/income history accurate
  /// to what actually should have happened, at the cost of possibly adding
  /// several rows at once if the app hasn't been opened in a while.
  Future<void> processDueRules() async {
    final rules = await (db.select(db.recurringRules)
          ..where((r) => r.isActive.equals(true)))
        .get();
    final now = DateTime.now();
    const maxCatchUp = 12;

    for (final rule in rules) {
      var dueDate = rule.nextDueDate;
      var count = 0;

      while (!dueDate.isAfter(now) && count < maxCatchUp) {
        if (rule.endDate != null && dueDate.isAfter(rule.endDate!)) break;

        if (rule.autoCreate) {
          if (rule.type == 'expense') {
            await expenseRepository.addExpense(
              amount: rule.amount,
              title: rule.title,
              categoryId: rule.categoryId,
              date: dueDate,
              recurringRuleId: rule.id,
            );
          } else if (rule.type == 'income' && rule.sourceId != null) {
            await incomeRepository.addIncome(
              amount: rule.amount,
              title: rule.title,
              sourceId: rule.sourceId!,
              date: dueDate,
              recurringRuleId: rule.id,
            );
          }
        }
        // If autoCreate is false, this is reminder-only — the UI layer
        // should separately surface "X is due" notifications; we still
        // advance nextDueDate so the reminder doesn't repeat endlessly.

        dueDate = _advance(dueDate, rule.frequency);
        count++;
      }

      if (count > 0) {
        await updateRule(rule.id, RecurringRulesCompanion(nextDueDate: Value(dueDate)));
      }
    }
  }
}
