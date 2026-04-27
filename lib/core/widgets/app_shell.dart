import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../router/route_names.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = <_NavItem>[
    _NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: RoutePaths.dashboard,
    ),
    _NavItem(
      label: 'Invoices',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      path: RoutePaths.invoices,
    ),
    _NavItem(
      label: 'Quotations',
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      path: RoutePaths.quotations,
    ),
    _NavItem(
      label: 'Customers',
      icon: Icons.people_alt_outlined,
      activeIcon: Icons.people_alt_rounded,
      path: RoutePaths.customers,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      path: RoutePaths.settings,
    ),
  ];

  int get _currentIndex {
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final createRouteName = switch (_currentIndex) {
      1 => RouteNames.invoiceForm,
      2 => RouteNames.quotationForm,
      _ => null,
    };

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
      floatingActionButton: createRouteName != null
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => context.goNamed(createRouteName),
              icon: const Icon(Icons.add_rounded),
              label: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Text(_currentIndex == 1 ? 'New Invoice' : 'New Quote'),
              ),
            )
          : null,
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
