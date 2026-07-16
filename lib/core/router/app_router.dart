import 'package:go_router/go_router.dart';
import '../widgets/app_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/expenses/list/expense_list_screen.dart';
import '../../features/expenses/add_edit/add_edit_expense_screen.dart';

/// 5-tab bottom nav: Dashboard, Expenses, Split, Analytics, Settings.
/// Everything else (Income, Savings, Budgets, Accounts, Recurring, Backup,
/// About) lives behind the side drawer, reachable from any tab — see design.md.
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpenseListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditExpenseScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => AddEditExpenseScreen(
                expenseId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        // '/split', '/analytics', '/settings' routes added as those
        // features are built out in later phases.
      ],
    ),
  ],
);
