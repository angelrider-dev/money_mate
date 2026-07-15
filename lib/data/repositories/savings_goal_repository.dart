import 'package:drift/drift.dart';
import '../local/database.dart';

class SavingsGoalRepository {
  final AppDatabase db;
  SavingsGoalRepository(this.db);

  Stream<List<SavingsGoal>> watchActiveGoals() {
    return (db.select(db.savingsGoals)
          ..where((g) => g.isCompleted.equals(false))
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Stream<List<SavingsGoal>> watchCompletedGoals() {
    return (db.select(db.savingsGoals)..where((g) => g.isCompleted.equals(true))).watch();
  }

  Future<int> createGoal({
    required String title,
    required double targetAmount,
    DateTime? targetDate,
    String? icon,
    String? coverImagePath,
  }) {
    return db.into(db.savingsGoals).insert(
          SavingsGoalsCompanion.insert(
            title: title,
            targetAmount: targetAmount,
            targetDate: Value(targetDate),
            icon: Value(icon),
            coverImagePath: Value(coverImagePath),
          ),
        );
  }

  Future<void> updateGoal(int id, SavingsGoalsCompanion changes) {
    return (db.update(db.savingsGoals)..where((g) => g.id.equals(id))).write(changes);
  }

  Stream<List<SavingsContribution>> watchContributions(int goalId) {
    return (db.select(db.savingsContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  /// Adds a contribution and updates the goal's running saved total in one
  /// transaction. Auto-marks the goal completed if the target is reached.
  Future<void> addContribution({
    required int goalId,
    required double amount,
    String? note,
  }) async {
    await db.transaction(() async {
      await db.into(db.savingsContributions).insert(
            SavingsContributionsCompanion.insert(
              goalId: goalId,
              amount: amount,
              note: Value(note),
            ),
          );

      final goal = await (db.select(db.savingsGoals)..where((g) => g.id.equals(goalId)))
          .getSingle();
      final newSaved = goal.savedAmount + amount;

      await (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId))).write(
        SavingsGoalsCompanion(
          savedAmount: Value(newSaved),
          isCompleted: Value(newSaved >= goal.targetAmount),
        ),
      );
    });
  }
}
