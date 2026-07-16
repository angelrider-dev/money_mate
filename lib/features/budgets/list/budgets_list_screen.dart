import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/providers/expense_providers.dart';
import '../../../data/local/database.dart';

/// month format used throughout: "2026-07"
String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

final _selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

class BudgetsListScreen extends ConsumerWidget {
  const BudgetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(_selectedMonthProvider);
    final monthKey = _monthKey(selectedMonth);
    final budgetsAsync = ref.watch(budgetsForMonthProvider(monthKey));
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/budgets/add?month=$monthKey'),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => ref.read(_selectedMonthProvider.notifier).state =
                        DateTime(selectedMonth.year, selectedMonth.month - 1),
                  ),
                  Text(_monthLabel(selectedMonth), style: AppTypography.titleMd),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => ref.read(_selectedMonthProvider.notifier).state =
                        DateTime(selectedMonth.year, selectedMonth.month + 1),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return const Center(child: Text('No budgets set for this month'));
                }
                return categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (categories) {
                    final categoryMap = {for (final c in categories) c.id: c};
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: budgets.length,
                      itemBuilder: (context, i) => _BudgetCard(
                        budget: budgets[i],
                        category: categoryMap[budgets[i].categoryId],
                        monthStart: DateTime(selectedMonth.year, selectedMonth.month, 1),
                        monthEnd: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;
  final Category? category;
  final DateTime monthStart;
  final DateTime monthEnd;

  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.monthStart,
    required this.monthEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetRepo = ref.watch(budgetRepositoryProvider);

    return FutureBuilder<double>(
      future: budgetRepo.spentForCategoryInMonth(budget.categoryId, monthStart, monthEnd),
      builder: (context, snapshot) {
        final spent = snapshot.data ?? 0;
        final limit = budget.limitAmount;
        final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
        final alertLevel = budgetRepo.alertLevel(spent, limit);

        Color progressColor;
        switch (alertLevel) {
          case 'exceeded':
            progressColor = AppColors.error;
          case 'danger':
            progressColor = AppColors.danger;
          case 'warning':
            progressColor = AppColors.warning;
          default:
            progressColor = AppColors.income;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.category_outlined, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(category?.name ?? 'Unknown', style: AppTypography.titleMd),
                    ),
                    Text(
                      '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                      style: AppTypography.bodyMd,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
                if (alertLevel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alertLevel == 'exceeded'
                        ? 'Budget exceeded'
                        : 'Budget limit nearly reached',
                    style: AppTypography.bodyMd.copyWith(color: progressColor),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
