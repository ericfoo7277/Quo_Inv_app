import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoice_detail_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/quotations/presentation/quotation_detail_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../widgets/app_shell.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRoute _appRoute({
  required String path,
  required String name,
  required Widget Function(BuildContext, GoRouterState) builder,
  List<RouteBase> routes = const [],
}) {
  return GoRoute(path: path, name: name, builder: builder, routes: routes);
}

GoRoute _detailRoute({
  required String name,
  required Widget Function(String id) builder,
}) {
  return GoRoute(
    path: ':id',
    name: name,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (_, state) => builder(state.pathParameters['id'] ?? ''),
  );
}

List<RouteBase> _publicRoutes() => [
      _appRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      _appRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      _appRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
    ];

List<RouteBase> _shellRoutes() => [
      _appRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      _appRoute(
        path: RoutePaths.invoices,
        name: RouteNames.invoices,
        builder: (_, __) => const InvoicesScreen(),
        routes: [
          _detailRoute(
            name: RouteNames.invoiceDetail,
            builder: (id) => InvoiceDetailScreen(id: id),
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.quotations,
        name: RouteNames.quotations,
        builder: (_, __) => const QuotationsScreen(),
        routes: [
          _detailRoute(
            name: RouteNames.quotationDetail,
            builder: (id) => QuotationDetailScreen(id: id),
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.customers,
        name: RouteNames.customers,
        builder: (_, __) => const CustomersScreen(),
        routes: [
          _detailRoute(
            name: RouteNames.customerDetail,
            builder: (id) => CustomerDetailScreen(id: id),
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.payments,
        name: RouteNames.payments,
        builder: (_, __) => const PaymentsScreen(),
      ),
      _appRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
    ];

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      ..._publicRoutes(),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: _shellRoutes(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
