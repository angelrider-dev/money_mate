import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/local/database.dart';

class RecurringRulesListScreen extends ConsumerWidget {
  const RecurringRulesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(activeRecurringRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/recurring/add'),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(
                child: Text('No recurring rules yet — set up rent, subscriptions, salary, etc.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: rules.length,
            itemBuilder: (context, i) => _RuleCard(rule: rules[i]),
          );
        },
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  final RecurringRule rule;
  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = rule.type == 'expense';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isExpense ? AppColors.errorContainer : AppColors.secondaryContainer,
              child: Icon(
                isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: isExpense ? AppColors.onErrorContainer : AppColors.onSecondaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title, style: AppTypography.bodyLg),
                  Text(
                    '${rule.frequency[0].toUpperCase()}${rule.frequency.substring(1)} · '
                    'Next: ${DateFormat('MMM d').format(rule.nextDueDate)}',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '\$${rule.amount.toStringAsFixed(2)}',
              style: AppTypography.bodyLg.copyWith(
                color: isExpense ? AppColors.error : AppColors.income,
                fontWeight: FontWeight.w600,
              ),
            ),
            Switch(
              value: rule.isActive,
              onChanged: (v) {
                if (!v) {
                  ref.read(recurringRuleRepositoryProvider).deactivateRule(rule.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
