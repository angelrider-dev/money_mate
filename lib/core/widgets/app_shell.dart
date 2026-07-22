import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../data/providers/repository_providers.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/expenses')) return 1;
    if (location.startsWith('/split')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/expenses');
            case 2:
              context.go('/split');
            case 3:
              context.go('/analytics');
            case 4:
              context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Split'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

/// Side drawer per design.md — secondary destinations not on the bottom nav.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiAccountAsync = ref.watch(multiAccountEnabledProvider);
    final multiAccountEnabled = multiAccountAsync.value ?? false;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Row(
                children: [
                  CircleAvatar(radius: 28, child: Icon(Icons.person_outline)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Me', style: AppTypography.titleMd),
                      Text('PKR', style: AppTypography.bodyMd),
                    ],
                  ),
                ],
              ),
            ),
            _drawerTile(context, Icons.account_balance_wallet_outlined, 'Income', '/income',
                enabled: true),
            _drawerTile(context, Icons.savings_outlined, 'Savings Goals', '/savings',
                enabled: true),
            _drawerTile(context, Icons.pie_chart_outline, 'Budgets', '/budgets',
                enabled: true),
            const Divider(),
            // Accounts only shown once multi-account is enabled in Settings.
            if (multiAccountEnabled)
              _drawerTile(
                  context, Icons.account_balance_outlined, 'Accounts', '/accounts',
                  enabled: true),
            _drawerTile(context, Icons.autorenew, 'Recurring Transactions', '/recurring',
                enabled: true),
            const Divider(),
            _drawerTile(context, Icons.backup_outlined, 'Backup & Restore', '/settings/backup',
                enabled: true),
            _drawerTile(context, Icons.info_outline, 'About', '/settings/about',
                enabled: true),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, String route,
      {bool enabled = false}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: AppTypography.bodyLg),
      enabled: enabled,
      onTap: enabled
          ? () {
              Navigator.of(context).pop();
              context.push(route);
            }
          : null,
    );
  }
}
