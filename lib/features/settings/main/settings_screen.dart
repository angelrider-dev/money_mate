import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final multiAccountAsync = ref.watch(multiAccountEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card — no email/login, per decision
          userAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (user) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        backgroundImage: user?.avatarPath != null
                            ? FileImage(File(user!.avatarPath!))
                            : null,
                        child: user?.avatarPath == null
                            ? const Icon(Icons.person_outline, size: 36)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? 'Me', style: AppTypography.titleMd),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.push('/settings/profile'),
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Text('PREFERENCES', style: AppTypography.labelMd),
          Card(
            child: Column(
              children: [
                userAsync.when(
                  data: (user) => ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Currency'),
                    subtitle: Text(user?.currency ?? 'PKR'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCurrencyPicker(context, ref),
                  ),
                  loading: () => const ListTile(title: Text('Currency')),
                  error: (e, _) => const ListTile(title: Text('Currency')),
                ),
                const Divider(height: 1),
                multiAccountAsync.when(
                  data: (enabled) => SwitchListTile(
                    secondary: const Icon(Icons.account_balance_outlined),
                    title: const Text('Multi-Account Support'),
                    subtitle: const Text('Track Cash, Bank, Card separately'),
                    value: enabled,
                    onChanged: (v) =>
                        ref.read(accountRepositoryProvider).setMultiAccountEnabled(v),
                  ),
                  loading: () => const ListTile(title: Text('Multi-Account Support')),
                  error: (e, _) => const ListTile(title: Text('Multi-Account Support')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('PRIVACY & SECURITY', style: AppTypography.labelMd),
          Card(
            child: Column(
              children: [
                userAsync.when(
                  data: (user) => SwitchListTile(
                    secondary: const Icon(Icons.lock_outline),
                    title: const Text('App Lock (PIN)'),
                    subtitle: const Text('Local only — not linked to any account'),
                    value: user?.appLockEnabled ?? false,
                    onChanged: (v) => _toggleAppLock(context, ref, v),
                  ),
                  loading: () => const ListTile(title: Text('App Lock')),
                  error: (e, _) => const ListTile(title: Text('App Lock')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup & Restore'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('APPLICATION', style: AppTypography.labelMd),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About MoneyMate'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/about'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: ['PKR', 'USD']
              .map((c) => ListTile(
                    title: Text(c),
                    onTap: () {
                      ref.read(userRepositoryProvider).updateCurrency(c);
                      Navigator.of(context).pop();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _toggleAppLock(BuildContext context, WidgetRef ref, bool enable) async {
    if (!enable) {
      await ref.read(userRepositoryProvider).setAppLock(enabled: false);
      return;
    }
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set a PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '4-6 digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (pin != null && pin.length >= 4) {
      await ref.read(userRepositoryProvider).setAppLock(enabled: true, pin: pin);
    }
  }
}
