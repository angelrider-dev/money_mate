import 'package:drift/drift.dart';

part 'database.g.dart';

/// Personal or group categories (Food, Travel, Rent, etc.)
/// Never hard-deleted if in use — archive instead, so existing Expenses
/// referencing this category never break with a foreign-key violation.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()(); // icon name/codepoint
  TextColumn get colorHex => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// A group for bill-splitting (e.g. "Goa Trip", "Flatmates")
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// A person — either the app user or someone added to a group (no login needed for them)
/// Archive instead of delete — a member with existing ExpenseSplits/Settlements
/// history must never be hard-removed, or that history becomes orphaned/broken.
class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get avatarColor => text().nullable()();
  BoolColumn get isCurrentUser => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Link table: which members belong to which group
class GroupMembers extends Table {
  IntColumn get groupId => integer().references(Groups, #id)();
  IntColumn get memberId => integer().references(Members, #id)();

  @override
  Set<Column> get primaryKey => {groupId, memberId};
}

/// Core expense — works for BOTH personal expenses (groupId = null)
/// and group/bill-split expenses (groupId set)
@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_category', columns: {#categoryId})
@TableIndex(name: 'idx_expenses_group', columns: {#groupId})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();

  // nullable to support Quick Add (amount/photo-only save with no category yet)
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();

  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().nullable()();

  // true = added via Quick Add and not yet fully filled in (category/title/etc.)
  // surfaced to the user as "X expenses need review" until they complete it
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  // null = personal expense; set = belongs to a group / bill split
  IntColumn get groupId => integer().nullable().references(Groups, #id)();

  // who actually paid (for splits). null for personal expenses.
  IntColumn get paidByMemberId => integer().nullable().references(Members, #id)();

  TextColumn get splitType =>
      text().withDefault(const Constant('equal'))(); // equal | exact | percentage

  // optional — only used if multi-account is enabled (see AppSettings)
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  // recurring source — null if this is a one-off, manually added expense
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();

  // soft delete — never hard-delete rows, so Undo always works
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// How an expense is split across members
/// e.g. Expense 500 rs, split among 3 members -> 3 rows here
@TableIndex(name: 'idx_splits_expense', columns: {#expenseId})
@TableIndex(name: 'idx_splits_member', columns: {#memberId})
class ExpenseSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get expenseId => integer().references(Expenses, #id)();
  IntColumn get memberId => integer().references(Members, #id)();
  RealColumn get shareAmount => real()(); // how much this member owes
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
}

/// Budgets — per category, per month (personal only)
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get limitAmount => real()();
  TextColumn get month => text()(); // format: "2026-07"
}

/// Settlement records — when someone pays back another member
class Settlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(Groups, #id)();
  @ReferenceName('settlementsAsDebtor')
  IntColumn get fromMemberId => integer().references(Members, #id)();
  @ReferenceName('settlementsAsCreditor')
  IntColumn get toMemberId => integer().references(Members, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// MoneyMate additions (personal finance features)
// ─────────────────────────────────────────────

/// Single local user profile — no auth/login, just app-level settings.
///
/// SINGLE-ROW TABLE: exactly one row must ever exist, with id = 1.
/// Enforcement is at the repository level, not the DB level (Drift doesn't
/// support a "max 1 row" constraint directly):
///   - UserRepository.getOrCreateUser() must be the ONLY way this table is
///     written to — it checks for an existing row first via
///     `select(users)..where((u) => u.id.equals(1))`, and only inserts a
///     default row (id: 1, name: 'Me', currency: 'PKR') if none exists.
///   - Never call `into(users).insert(...)` directly from anywhere else.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('Me'))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get avatarPath => text().nullable()();

  // local app-lock (PIN/biometric) — NOT cloud auth, just a lock screen
  // shown when the app is opened, purely on-device.
  TextColumn get pinHash => text().nullable()(); // hashed PIN, never store plaintext
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get appLockEnabled =>
      boolean().withDefault(const Constant(false))();
}

/// Income sources: Salary, Freelance, Business, Investments, Gifts, Other
/// Archived (not deleted) when in use by existing Income rows.
class IncomeSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Actual income entries
@TableIndex(name: 'idx_income_date', columns: {#date})
class Income extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  IntColumn get sourceId => integer().references(IncomeSources, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  // optional — only used if multi-account is enabled
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Savings goals: "Buy a Laptop", "Emergency Fund", etc.
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get icon => text().nullable()();
  // optional cover photo shown behind the goal (e.g. a photo of the car/trip
  // the user is saving for) — purely cosmetic, stored as a local file path
  TextColumn get coverImagePath => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Contributions towards a savings goal (so progress has a history, not just a running total)
class SavingsContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

/// App-level settings (theme, notification prefs, etc.) — simple key/value.
/// Multi-account is OFF by default — check key 'multi_account_enabled' == 'true'
/// before showing account pickers/balances in the UI. Until enabled, everything
/// implicitly uses a single hidden "default" account.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Optional — only relevant once user enables multi-account in Settings.
/// Cash, Bank, Credit Card, etc. A single "Default" row always exists
/// so Expenses/Income can always link to *an* account even when the
/// feature is toggled off (UI just never exposes the picker in that case).
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type =>
      text().withDefault(const Constant('cash'))(); // cash | bank | card | wallet
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  TextColumn get icon => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Transfers between accounts — not an expense, not an income.
/// Only used when multi-account is enabled.
class AccountTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('transfersOut')
  IntColumn get fromAccountId => integer().references(Accounts, #id)();
  @ReferenceName('transfersIn')
  IntColumn get toAccountId => integer().references(Accounts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

/// Rule for auto-generating recurring Expenses/Income (rent, subscriptions, salary).
/// A background check (e.g. run on app open) compares 'nextDueDate' to today
/// and creates the actual Expense/Income row when due.
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'expense' | 'income'

  // for expense rules
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  // for income rules
  IntColumn get sourceId => integer().nullable().references(IncomeSources, #id)();

  TextColumn get frequency =>
      text()(); // 'daily' | 'weekly' | 'monthly' | 'yearly'
  DateTimeColumn get nextDueDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()(); // null = repeats forever

  // true = auto-create the transaction silently; false = just remind the user
  BoolColumn get autoCreate => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Categories,
  Groups,
  Members,
  GroupMembers,
  Expenses,
  ExpenseSplits,
  Budgets,
  Settlements,
  Users,
  IncomeSources,
  Income,
  SavingsGoals,
  SavingsContributions,
  AppSettings,
  Accounts,
  AccountTransfers,
  RecurringRules,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
