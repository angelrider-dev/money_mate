import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/expense_providers.dart';
import '../../../data/local/database.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/expenses/add'),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/expenses/add'));
          }
          final grouped = _groupByDate(expenses);
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return _DateSection(label: entry.key, expenses: entry.value);
            },
          );
        },
      ),
    );
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<Expense>>{};

    for (final e in expenses) {
      String label;
      if (_isSameDay(e.date, today)) {
        label = 'Today';
      } else if (_isSameDay(e.date, yesterday)) {
        label = 'Yesterday';
      } else {
        label = DateFormat('d MMMM').format(e.date);
      }
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSection extends StatelessWidget {
  final String label;
  final List<Expense> expenses;
  const _DateSection({required this.label, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(label.toUpperCase(), style: AppTypography.labelMd),
        ),
        ...expenses.map((e) => _ExpenseTile(expense: e)),
      ],
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(expenseRepositoryProvider).softDelete(expense.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Expense deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () =>
                    ref.read(expenseRepositoryProvider).undoDelete(expense.id),
              ),
            ),
          );
        }
      },
      child: ListTile(
        onTap: () => context.push('/expenses/edit/${expense.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainerHigh,
          child: const Icon(Icons.receipt_outlined, size: 20),
        ),
        title: Text(expense.title, style: AppTypography.bodyLg),
        subtitle: Text(
          DateFormat('h:mm a').format(expense.date),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        trailing: Text(
          '-\$${expense.amount.toStringAsFixed(2)}',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('No expenses yet', style: AppTypography.titleMd),
          const SizedBox(height: 4),
          Text(
            'Tap below to add your first expense',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}
