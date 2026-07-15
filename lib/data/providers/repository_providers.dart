import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../repositories/income_repository.dart';
import '../repositories/group_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/savings_goal_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/recurring_rule_repository.dart';
import 'database_provider.dart';
import 'expense_providers.dart';

// ── Income ──────────────────────────────────────────
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(databaseProvider));
});

final incomeSourceRepositoryProvider = Provider<IncomeSourceRepository>((ref) {
  return IncomeSourceRepository(ref.watch(databaseProvider));
});

final allIncomeProvider = StreamProvider<List<IncomeData>>((ref) {
  return ref.watch(incomeRepositoryProvider).watchAll();
});

final activeIncomeSourcesProvider = StreamProvider<List<IncomeSource>>((ref) {
  return ref.watch(incomeSourceRepositoryProvider).watchActive();
});

// ── Groups / Bill Splitting ──────────────────────────
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(databaseProvider));
});

final activeGroupsProvider = StreamProvider<List<Group>>((ref) {
  return ref.watch(groupRepositoryProvider).watchActiveGroups();
});

final activeMembersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(groupRepositoryProvider).watchActiveMembers();
});

final groupExpensesProvider = StreamProvider.family<List<Expense>, int>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupExpenses(groupId);
});

final groupBalancesProvider = FutureProvider.family<Map<int, double>, int>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).computeGroupBalances(groupId);
});

// ── Budgets ─────────────────────────────────────────
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

final budgetsForMonthProvider = StreamProvider.family<List<Budget>, String>((ref, month) {
  return ref.watch(budgetRepositoryProvider).watchForMonth(month);
});

// ── Savings Goals ────────────────────────────────────
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(ref.watch(databaseProvider));
});

final activeSavingsGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(savingsGoalRepositoryProvider).watchActiveGoals();
});

final goalContributionsProvider =
    StreamProvider.family<List<SavingsContribution>, int>((ref, goalId) {
  return ref.watch(savingsGoalRepositoryProvider).watchContributions(goalId);
});

// ── Accounts (optional feature) ──────────────────────
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(databaseProvider));
});

final multiAccountEnabledProvider = FutureProvider<bool>((ref) {
  return ref.watch(accountRepositoryProvider).isMultiAccountEnabled();
});

final activeAccountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchActiveAccounts();
});

// ── Recurring Rules ───────────────────────────────────
final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>((ref) {
  return RecurringRuleRepository(
    ref.watch(databaseProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
  );
});

final activeRecurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(recurringRuleRepositoryProvider).watchActiveRules();
});
