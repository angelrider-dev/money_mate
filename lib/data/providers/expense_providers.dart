import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../repositories/expense_repository.dart';
import '../repositories/category_repository.dart';
import 'database_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepository(db);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

/// Reactive stream — Expense List / Dashboard watch this and rebuild automatically.
final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

/// Expenses added via Quick Add that still need category/details filled in.
final needsReviewExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchNeedsReview();
});

final activeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchActive();
});

/// Family provider — watch expenses for one specific category (e.g. Budgets screen).
final expensesByCategoryProvider =
    StreamProvider.family<List<Expense>, int>((ref, categoryId) {
  return ref.watch(expenseRepositoryProvider).watchByCategory(categoryId);
});
