import 'package:go_router/go_router.dart';

import '../shell/app_shell.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/accounts/presentation/accounts_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/categories/presentation/categories_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },

      branches: [
        // Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) {
                return const DashboardPage();
              },
            ),
          ],
        ),

        // Accounts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              name: 'accounts',
              builder: (context, state) {
                return const AccountsPage();
              },
            ),
          ],
        ),

        // Transactions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              name: 'transactions',
              builder: (context, state) {
                return const TransactionsPage();
              },
            ),
          ],
        ),

        // Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (context, state) {
                return const ReportsPage();
              },
            ),
          ],
        ),

        // Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) {
                return const SettingsPage();
              },
              routes: [
                GoRoute(
                  path: 'categories',
                  name: 'categories',
                  builder: (context, state) {
                    return const CategoriesPage();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
