import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/local/database.dart';

class SavingsGoalsListScreen extends ConsumerWidget {
  const SavingsGoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeSavingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // Total saved summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL SAVED',
                        style: AppTypography.labelMd.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${goals.fold<double>(0, (s, g) => s + g.savedAmount).toStringAsFixed(2)}',
                      style: AppTypography.numericXl.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Goals', style: AppTypography.titleMd),
                  TextButton.icon(
                    onPressed: () => context.push('/savings/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),

              if (goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No goals yet — create your first one!')),
                )
              else
                ...goals.map((g) => _GoalCard(goal: g)),
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final ratio = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/savings/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondaryContainer,
                    child: Icon(Icons.savings_outlined, color: AppColors.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(goal.title, style: AppTypography.titleMd)),
                  Text('\$${goal.targetAmount.toStringAsFixed(0)}',
                      style: AppTypography.bodyLg),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation(AppColors.income),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved: \$${goal.savedAmount.toStringAsFixed(0)}',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.income)),
                  Text('${(ratio * 100).toStringAsFixed(0)}% reached',
                      style: AppTypography.bodyMd),
                ],
              ),
              if (goal.targetDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Target date: ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
