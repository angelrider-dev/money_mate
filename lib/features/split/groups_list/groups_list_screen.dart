import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/local/database.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(activeGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Groups')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/split/create'),
        icon: const Icon(Icons.group_add_outlined, color: AppColors.onPrimary),
        label: const Text('Create Group', style: TextStyle(color: AppColors.onPrimary)),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyState(onCreate: () => context.push('/split/create'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: groups.length,
            itemBuilder: (context, i) => _GroupCard(group: groups[i]),
          );
        },
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(group.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/split/${group.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: AppTypography.titleMd),
                    const SizedBox(height: 4),
                    balancesAsync.when(
                      loading: () => const SizedBox(
                          height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => const Text('—'),
                      data: (balances) {
                        // "You" balance — assumes the current user's member row
                        // is looked up elsewhere; for now show group net total.
                        final net = balances.values.fold<double>(0, (s, v) => s + v.abs()) / 2;
                        return Text(
                          net == 0 ? 'Settled up' : 'Total activity: \$${net.toStringAsFixed(2)}',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('No groups yet', style: AppTypography.titleMd),
          const SizedBox(height: 4),
          Text(
            'Create a group to start splitting bills with friends',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}
