import 'package:go_router/go_router.dart';
import '../widgets/app_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/expenses/list/expense_list_screen.dart';
import '../../features/expenses/add_edit/add_edit_expense_screen.dart';
import '../../features/income/list/income_list_screen.dart';
import '../../features/income/add_edit/add_edit_income_screen.dart';
import '../../features/split/groups_list/groups_list_screen.dart';
import '../../features/split/create_group/create_group_screen.dart';
import '../../features/split/group_details/group_details_screen.dart';
import '../../features/split/add_group_expense/add_group_expense_screen.dart';
import '../../features/split/settle_up/settle_up_screen.dart';
import '../../features/categories/list/categories_list_screen.dart';
import '../../features/categories/add_edit/add_edit_category_screen.dart';
import '../../features/budgets/list/budgets_list_screen.dart';
import '../../features/budgets/set_budget/set_budget_screen.dart';

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
        GoRoute(
          path: '/split',
          builder: (context, state) => const GroupsListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateGroupScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => GroupDetailsScreen(
                groupId: int.parse(state.pathParameters['id']!),
              ),
              routes: [
                GoRoute(
                  path: 'add-expense',
                  builder: (context, state) => AddGroupExpenseScreen(
                    groupId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'settle-up',
                  builder: (context, state) => SettleUpScreen(
                    groupId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        // '/analytics', '/settings' routes added as those
        // features are built out in later phases.
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => SetBudgetScreen(
                month: state.uri.queryParameters['month'] ??
                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditCategoryScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => AddEditCategoryScreen(
                categoryId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/income',
          builder: (context, state) => const IncomeListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditIncomeScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => AddEditIncomeScreen(
                incomeId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
