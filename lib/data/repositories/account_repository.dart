import 'package:drift/drift.dart';
import '../local/database.dart';

class AccountRepository {
  final AppDatabase db;
  AccountRepository(this.db);

  static const _multiAccountKey = 'multi_account_enabled';

  /// Whether the multi-account feature is turned on in Settings.
  /// Defaults to false (off) if the setting has never been written.
  Future<bool> isMultiAccountEnabled() async {
    final row = await (db.select(db.appSettings)
          ..where((s) => s.key.equals(_multiAccountKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> setMultiAccountEnabled(bool enabled) {
    return db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _multiAccountKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  Stream<List<Account>> watchActiveAccounts() {
    return (db.select(db.accounts)..where((a) => a.isArchived.equals(false))).watch();
  }

  /// The always-present hidden "Default" account, used transparently
  /// whenever multi-account is disabled.
  Future<Account> getDefaultAccount() async {
    final existing = await (db.select(db.accounts)
          ..where((a) => a.name.equals('Default')))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Default', type: const Value('cash')));
    return (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<int> addAccount({
    required String name,
    String type = 'cash',
    double openingBalance = 0,
    String? icon,
  }) {
    return db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: name,
            type: Value(type),
            openingBalance: Value(openingBalance),
            icon: Value(icon),
          ),
        );
  }

  Future<void> archiveAccount(int id) {
    return (db.update(db.accounts)..where((a) => a.id.equals(id)))
        .write(const AccountsCompanion(isArchived: Value(true)));
  }

  /// Current balance = opening balance + all income - all expenses - transfers out + transfers in.
  Future<double> currentBalance(int accountId) async {
    final account = await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
        .getSingle();

    final expenses = await (db.select(db.expenses)
          ..where((e) => e.accountId.equals(accountId) & e.isDeleted.equals(false)))
        .get();
    final income = await (db.select(db.income)
          ..where((i) => i.accountId.equals(accountId) & i.isDeleted.equals(false)))
        .get();
    final transfersOut =
        await (db.select(db.accountTransfers)..where((t) => t.fromAccountId.equals(accountId)))
            .get();
    final transfersIn =
        await (db.select(db.accountTransfers)..where((t) => t.toAccountId.equals(accountId)))
            .get();

    var balance = account.openingBalance;
    balance -= expenses.fold<double>(0, (sum, e) => sum + e.amount);
    balance += income.fold<double>(0, (sum, i) => sum + i.amount);
    balance -= transfersOut.fold<double>(0, (sum, t) => sum + t.amount);
    balance += transfersIn.fold<double>(0, (sum, t) => sum + t.amount);
    return balance;
  }

  Future<int> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    String? note,
  }) {
    return db.into(db.accountTransfers).insert(
          AccountTransfersCompanion.insert(
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amount: amount,
            note: Value(note),
          ),
        );
  }
}
