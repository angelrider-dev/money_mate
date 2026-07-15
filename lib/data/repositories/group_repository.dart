import 'package:drift/drift.dart';
import '../local/database.dart';
import 'split_calculator.dart';

class GroupRepository {
  final AppDatabase db;
  GroupRepository(this.db);

  // ── Groups ──────────────────────────────────────────
  Stream<List<Group>> watchActiveGroups() {
    return (db.select(db.groups)..where((g) => g.isArchived.equals(false))).watch();
  }

  Future<int> createGroup(String name) {
    return db.into(db.groups).insert(GroupsCompanion.insert(name: name));
  }

  Future<void> archiveGroup(int id) {
    return (db.update(db.groups)..where((g) => g.id.equals(id)))
        .write(const GroupsCompanion(isArchived: Value(true)));
  }

  // ── Members ─────────────────────────────────────────
  Stream<List<Member>> watchActiveMembers() {
    return (db.select(db.members)..where((m) => m.isArchived.equals(false))).watch();
  }

  Future<int> addMember(String name, {bool isCurrentUser = false}) {
    return db.into(db.members).insert(
          MembersCompanion.insert(
            name: name,
            isCurrentUser: Value(isCurrentUser),
          ),
        );
  }

  Future<void> archiveMember(int id) {
    return (db.update(db.members)..where((m) => m.id.equals(id)))
        .write(const MembersCompanion(isArchived: Value(true)));
  }

  Future<void> addMemberToGroup(int groupId, int memberId) {
    return db.into(db.groupMembers).insert(
          GroupMembersCompanion.insert(groupId: groupId, memberId: memberId),
        );
  }

  Stream<List<Member>> watchGroupMembers(int groupId) {
    final query = db.select(db.members).join([
      innerJoin(
        db.groupMembers,
        db.groupMembers.memberId.equalsExp(db.members.id),
      ),
    ])
      ..where(db.groupMembers.groupId.equals(groupId) & db.members.isArchived.equals(false));
    return query.watch().map((rows) => rows.map((r) => r.readTable(db.members)).toList());
  }

  // ── Group Expenses + Splits ─────────────────────────

  /// Adds a group expense and creates its splits in one transaction.
  /// [shares] should be pre-calculated via SplitCalculator (equal/exact/percentage)
  /// before calling this — this method just persists the result.
  Future<int> addGroupExpense({
    required String title,
    required double amount,
    int? categoryId,
    required DateTime date,
    required int groupId,
    required int paidByMemberId,
    required String splitType,
    required Map<int, double> shares, // memberId -> owed amount
    String? note,
  }) async {
    return db.transaction(() async {
      final expenseId = await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              title: title,
              amount: amount,
              categoryId: Value(categoryId),
              date: date,
              groupId: Value(groupId),
              paidByMemberId: Value(paidByMemberId),
              splitType: Value(splitType),
              note: Value(note),
            ),
          );

      for (final entry in shares.entries) {
        await db.into(db.expenseSplits).insert(
              ExpenseSplitsCompanion.insert(
                expenseId: expenseId,
                memberId: entry.key,
                shareAmount: entry.value,
              ),
            );
      }
      return expenseId;
    });
  }

  Stream<List<Expense>> watchGroupExpenses(int groupId) {
    return (db.select(db.expenses)
          ..where((e) => e.groupId.equals(groupId) & e.isDeleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  Future<List<ExpenseSplit>> getSplitsForExpense(int expenseId) {
    return (db.select(db.expenseSplits)..where((s) => s.expenseId.equals(expenseId))).get();
  }

  // ── Balances & Settlement ────────────────────────────

  /// Computes each member's net balance within a group:
  /// positive = they are owed money, negative = they owe money.
  Future<Map<int, double>> computeGroupBalances(int groupId) async {
    final expenses = await (db.select(db.expenses)
          ..where((e) => e.groupId.equals(groupId) & e.isDeleted.equals(false)))
        .get();

    final balances = <int, double>{};

    for (final expense in expenses) {
      final splits = await getSplitsForExpense(expense.id);
      final payerId = expense.paidByMemberId;
      if (payerId == null) continue;

      // Payer gets credited the full amount they paid.
      balances[payerId] = (balances[payerId] ?? 0) + expense.amount;

      // Each member owing their share gets debited.
      for (final split in splits) {
        balances[split.memberId] = (balances[split.memberId] ?? 0) - split.shareAmount;
      }
    }

    // Apply already-recorded settlements (they reduce outstanding balances).
    final settlements =
        await (db.select(db.settlements)..where((s) => s.groupId.equals(groupId))).get();
    for (final s in settlements) {
      balances[s.fromMemberId] = (balances[s.fromMemberId] ?? 0) + s.amount;
      balances[s.toMemberId] = (balances[s.toMemberId] ?? 0) - s.amount;
    }

    return balances;
  }

  /// Returns minimal settlement suggestions ("who should pay whom") for a group.
  Future<List<SettlementSuggestion>> getSettlementSuggestions(int groupId) async {
    final balances = await computeGroupBalances(groupId);
    return SplitCalculator.simplifyDebts(balances);
  }

  Future<int> recordSettlement({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required double amount,
  }) {
    return db.into(db.settlements).insert(
          SettlementsCompanion.insert(
            groupId: groupId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amount: amount,
          ),
        );
  }
}
