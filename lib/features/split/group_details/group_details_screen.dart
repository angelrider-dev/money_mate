import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final int groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(activeGroupsProvider);
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final membersAsync = ref.watch(activeMembersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: groupsAsync.when(
            data: (groups) {
              final group = groups.where((g) => g.id == groupId).firstOrNull;
              return Text(group?.name ?? 'Group');
            },
            loading: () => const Text('Group'),
            error: (e, _) => const Text('Group'),
          ),
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Balances')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => context.push('/split/$groupId/add-expense'),
          icon: const Icon(Icons.add, color: AppColors.onPrimary),
          label: const Text('Add Expense', style: TextStyle(color: AppColors.onPrimary)),
        ),
        body: TabBarView(
          children: [
            // Expenses tab
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(child: Text('No expenses in this group yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: expenses.length,
                  itemBuilder: (context, i) {
                    final e = expenses[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Icon(Icons.receipt_outlined, size: 18),
                      ),
                      title: Text(e.title),
                      subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year}'),
                      trailing: Text(
                        '\$${e.amount.toStringAsFixed(2)}',
                        style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                );
              },
            ),

            // Balances tab
            balancesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (balances) {
                return membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (members) {
                    final memberMap = {for (final m in members) m.id: m};
                    final entries = balances.entries.where((e) => e.value.abs() > 0.01).toList();

                    if (entries.isEmpty) {
                      return const Center(child: Text('Everyone is settled up! 🎉'));
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: entries.map((e) {
                              final member = memberMap[e.key];
                              final owed = e.value > 0;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: owed
                                      ? AppColors.secondaryContainer
                                      : AppColors.errorContainer,
                                  child: Text(member?.name.substring(0, 1) ?? '?'),
                                ),
                                title: Text(member?.name ?? 'Unknown'),
                                trailing: Text(
                                  '${owed ? '+' : '-'}\$${e.value.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: owed ? AppColors.income : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/split/$groupId/settle-up'),
                              icon: const Icon(Icons.handshake_outlined),
                              label: const Text('Settle Up'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
