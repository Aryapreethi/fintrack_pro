import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/haptics.dart';
import '../../core/utils/hero_tags.dart';
import '../../l10n/generated/app_localizations.dart';
import '../transactions/add_transaction_flow.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  static const _tabs = <_ShellTab>[
    _ShellTab(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/dashboard',
    ),
    _ShellTab(
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      route: '/transactions',
    ),
    _ShellTab(
      label: 'Budget',
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings,
      route: '/budget',
    ),
    _ShellTab(
      label: 'Categories',
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      route: '/categories',
    ),
    _ShellTab(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: '/settings',
    ),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  Future<void> _handleBack(BuildContext context, int selected) async {
    if (selected != 0) {
      context.go('/dashboard');
      return;
    }
    final l = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.exitAppTitle),
        content: Text(l.exitAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.exit),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      if (Platform.isAndroid) {
        await SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _indexFor(location);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    final labelStyle = TextStyle(
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w600,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context, selected);
      },
      child: Scaffold(
        body: child,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Hero(
          tag: HeroTags.fabAdd,
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () async {
              await Haptics.tap();
              if (!context.mounted) return;
              await AddTransactionFlow.show(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => labelStyle,
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(size: compact ? 22 : 24),
            ),
          ),
          child: NavigationBar(
            height: compact ? 64 : 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: selected,
            onDestinationSelected: (i) async {
              if (i == selected) return;
              await Haptics.tap();
              if (!context.mounted) return;
              context.go(_tabs[i].route);
            },
            destinations: [
              for (final t in _tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}
