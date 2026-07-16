import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/expense_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('MoneyMate'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL BALANCE',
                    style: AppTypography.labelMd.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                expensesAsync.when(
                  loading: () => const CircularProgressIndicator(color: Colors.white),
                  error: (e, _) => const Text('—', style: TextStyle(color: Colors.white)),
                  data: (expenses) {
                    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
                    return Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: AppTypography.numericXl.copyWith(color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.income),
                  label: const Text('Add Income'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/expenses/add'),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.expense),
                  label: const Text('Add Expense'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Recent Transactions', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No transactions yet')),
                );
              }
              final recent = expenses.take(5).toList();
              return Column(
                children: recent
                    .map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            child: Icon(Icons.receipt_outlined, size: 18),
                          ),
                          title: Text(e.title),
                          trailing: Text(
                            '-\$${e.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
