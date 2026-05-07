import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/budget/budget_page.dart';
import '../features/categories/categories_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/main_shell.dart';
import '../features/transactions/transaction_detail_page.dart';
import '../features/transactions/transactions_list_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        observers: [HeroController()],
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fadePage(state, const DashboardPage()),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) =>
                _fadePage(state, const TransactionsListPage()),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => TransactionDetailPage(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, state) =>
                _fadePage(state, const BudgetPage()),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) =>
                _fadePage(state, const CategoriesPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsPage()),
          ),
        ],
      ),
    ],
  );
}

CustomTransitionPage<dynamic> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<dynamic>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondary, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: child,
      );
    },
  );
}
