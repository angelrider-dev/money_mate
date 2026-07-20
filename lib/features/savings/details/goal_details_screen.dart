import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class GoalDetailsScreen extends ConsumerWidget {
  final int goalId;
  const GoalDetailsScreen({super.key, required this.goalId});

  Future<void> _addContributionDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contribution'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', labelText: 'Amount'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await ref.read(savingsGoalRepositoryProvider).addContribution(
            goalId: goalId,
            amount: result,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeSavingsGoalsProvider);
    final contributionsAsync = ref.watch(goalContributionsProvider(goalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final goal = goals.where((g) => g.id == goalId).firstOrNull;
          if (goal == null) return const Center(child: Text('Goal not found'));

          final ratio =
              goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (goal.coverImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Image.file(File(goal.coverImagePath!),
                      height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),

              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 10,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(ratio * 100).toStringAsFixed(0)}%',
                              style: AppTypography.headlineLg),
                          Text('COMPLETED', style: AppTypography.labelMd),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '\$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                  style: AppTypography.titleMd,
                ),
              ),
              if (goal.targetDate != null)
                Center(
                  child: Text(
                    'Estimated completion: ${DateFormat('MMMM yyyy').format(goal.targetDate!)}',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () => _addContributionDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Funds'),
              ),
              const SizedBox(height: 24),

              Text('Recent Contributions', style: AppTypography.titleMd),
              const SizedBox(height: 8),
              contributionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (contributions) {
                  if (contributions.isEmpty) {
                    return const Text('No contributions yet');
                  }
                  return Column(
                    children: contributions
                        .map((c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.secondaryContainer,
                                child: Icon(Icons.add, size: 18, color: AppColors.onSecondaryContainer),
                              ),
                              title: Text(DateFormat('MMM d, yyyy').format(c.date)),
                              trailing: Text(
                                '+\$${c.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.income, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
