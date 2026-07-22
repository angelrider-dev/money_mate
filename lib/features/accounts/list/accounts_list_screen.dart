import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/local/database.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/accounts/add'),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts yet — add your first one'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (accounts.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/accounts/transfer'),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Transfer Between Accounts'),
                    ),
                  ),
                ),
              ...accounts.map((a) => _AccountCard(account: a)),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;
  const _AccountCard({required this.account});

  IconData _iconFor(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(accountRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<double>(
        future: repo.currentBalance(account.id),
        builder: (context, snapshot) {
          final balance = snapshot.data ?? account.openingBalance;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Icon(_iconFor(account.type), size: 20),
            ),
            title: Text(account.name, style: AppTypography.bodyLg),
            subtitle: Text(account.type.toUpperCase(), style: AppTypography.labelMd),
            trailing: Text(
              '\$${balance.toStringAsFixed(2)}',
              style: AppTypography.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: balance >= 0 ? AppColors.income : AppColors.error,
              ),
            ),
          );
        },
      ),
    );
  }
}
