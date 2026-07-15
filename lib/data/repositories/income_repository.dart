import 'package:drift/drift.dart';
import '../local/database.dart';

class IncomeRepository {
  final AppDatabase db;
  IncomeRepository(this.db);

  Stream<List<IncomeData>> watchAll() {
    return (db.select(db.income)
          ..where((i) => i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm.desc(i.date)]))
        .watch();
  }

  Stream<List<IncomeData>> watchByDateRange(DateTime start, DateTime end) {
    return (db.select(db.income)
          ..where((i) =>
              i.isDeleted.equals(false) &
              i.date.isBiggerOrEqualValue(start) &
              i.date.isSmallerOrEqualValue(end))
          ..orderBy([(i) => OrderingTerm.desc(i.date)]))
        .watch();
  }

  Stream<List<IncomeData>> watchBySource(int sourceId) {
    return (db.select(db.income)
          ..where((i) => i.isDeleted.equals(false) & i.sourceId.equals(sourceId))
          ..orderBy([(i) => OrderingTerm.desc(i.date)]))
        .watch();
  }

  Future<int> addIncome({
    required double amount,
    required String title,
    required int sourceId,
    required DateTime date,
    String? note,
    int? accountId,
    int? recurringRuleId,
  }) {
    return db.into(db.income).insert(
          IncomeCompanion.insert(
            title: title,
            amount: amount,
            sourceId: sourceId,
            date: date,
            note: Value(note),
            accountId: Value(accountId),
            recurringRuleId: Value(recurringRuleId),
          ),
        );
  }

  Future<void> updateIncome(int id, IncomeCompanion changes) {
    return (db.update(db.income)..where((i) => i.id.equals(id))).write(changes);
  }

  Future<void> softDelete(int id) {
    return updateIncome(
      id,
      IncomeCompanion(isDeleted: const Value(true), deletedAt: Value(DateTime.now())),
    );
  }

  Future<void> undoDelete(int id) {
    return updateIncome(
      id,
      const IncomeCompanion(isDeleted: Value(false), deletedAt: Value(null)),
    );
  }
}

class IncomeSourceRepository {
  final AppDatabase db;
  IncomeSourceRepository(this.db);

  Stream<List<IncomeSource>> watchActive() {
    return (db.select(db.incomeSources)..where((s) => s.isArchived.equals(false)))
        .watch();
  }

  Future<int> addSource({required String name, required String icon}) {
    return db
        .into(db.incomeSources)
        .insert(IncomeSourcesCompanion.insert(name: name, icon: icon));
  }

  Future<bool> isInUse(int sourceId) async {
    final rows = await (db.select(db.income)
          ..where((i) => i.sourceId.equals(sourceId) & i.isDeleted.equals(false)))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> archive(int id) {
    return (db.update(db.incomeSources)..where((s) => s.id.equals(id)))
        .write(const IncomeSourcesCompanion(isArchived: Value(true)));
  }

  Future<void> unarchive(int id) {
    return (db.update(db.incomeSources)..where((s) => s.id.equals(id)))
        .write(const IncomeSourcesCompanion(isArchived: Value(false)));
  }
}
