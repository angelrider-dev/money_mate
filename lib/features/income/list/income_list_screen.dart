import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/local/database.dart';

class IncomeListScreen extends ConsumerWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(allIncomeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/income/add'),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: incomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (incomeList) {
          if (incomeList.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/income/add'));
          }
          final grouped = _groupByDate(incomeList);
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return _DateSection(label: entry.key, items: entry.value);
            },
          );
        },
      ),
    );
  }

  Map<String, List<IncomeData>> _groupByDate(List<IncomeData> items) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<IncomeData>>{};

    for (final i in items) {
      String label;
      if (_isSameDay(i.date, today)) {
        label = 'Today';
      } else if (_isSameDay(i.date, yesterday)) {
        label = 'Yesterday';
      } else {
        label = DateFormat('d MMMM').format(i.date);
      }
      grouped.putIfAbsent(label, () => []).add(i);
    }
    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSection extends StatelessWidget {
  final String label;
  final List<IncomeData> items;
  const _DateSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(label.toUpperCase(), style: AppTypography.labelMd),
        ),
        ...items.map((i) => _IncomeTile(income: i)),
      ],
    );
  }
}

class _IncomeTile extends ConsumerWidget {
  final IncomeData income;
  const _IncomeTile({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(incomeRepositoryProvider).softDelete(income.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Income deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => ref.read(incomeRepositoryProvider).undoDelete(income.id),
              ),
            ),
          );
        }
      },
      child: ListTile(
        onTap: () => context.push('/income/edit/${income.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondaryContainer,
          child: const Icon(Icons.trending_up, size: 20, color: AppColors.onSecondaryContainer),
        ),
        title: Text(income.title, style: AppTypography.bodyLg),
        subtitle: Text(
          DateFormat('h:mm a').format(income.date),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        trailing: Text(
          '+\$${income.amount.toStringAsFixed(2)}',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.income,
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
          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('No income recorded yet', style: AppTypography.titleMd),
          const SizedBox(height: 4),
          Text(
            'Tap below to add your first income entry',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Income'),
          ),
        ],
      ),
    );
  }
}
