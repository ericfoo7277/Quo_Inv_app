import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoice_detail_screen.dart';
import '../../features/invoices/presentation/invoice_form_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/quotations/presentation/quotation_detail_screen.dart';
import '../../features/quotations/presentation/quotation_form_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/settings/presentation/business_profile_screen.dart';
import '../../features/settings/presentation/default_notes_screen.dart';
import '../../features/settings/presentation/numbering_settings_screen.dart';
import '../../features/settings/presentation/reminder_settings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/setup/presentation/business_setup_screen.dart';
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
      _appRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      _appRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      _appRoute(
        path: RoutePaths.businessSetup,
        name: RouteNames.businessSetup,
        builder: (_, __) => const BusinessSetupScreen(),
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
          GoRoute(
            path: 'new',
            name: RouteNames.invoiceForm,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const InvoiceFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.invoiceDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                InvoiceDetailScreen(id: state.pathParameters['id'] ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.invoiceEdit,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => InvoiceFormScreen(
                  invoiceId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.quotations,
        name: RouteNames.quotations,
        builder: (_, __) => const QuotationsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: RouteNames.quotationForm,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const QuotationFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.quotationDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                QuotationDetailScreen(id: state.pathParameters['id'] ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.quotationEdit,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => QuotationFormScreen(
                  quotationId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.customers,
        name: RouteNames.customers,
        builder: (_, __) => const CustomersScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: RouteNames.customerForm,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.customerDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                CustomerDetailScreen(id: state.pathParameters['id'] ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.customerEdit,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => CustomerFormScreen(
                  customerId: state.pathParameters['id'],
                ),
              ),
            ],
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
        routes: [
          GoRoute(
            path: 'business-profile',
            name: RouteNames.businessProfile,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const BusinessProfileScreen(),
          ),
          GoRoute(
            path: 'numbering',
            name: RouteNames.numberingSettings,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const NumberingSettingsScreen(),
          ),
          GoRoute(
            path: 'reminders',
            name: RouteNames.reminderSettings,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const ReminderSettingsScreen(),
          ),
          GoRoute(
            path: 'default-notes',
            name: RouteNames.defaultNotes,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const DefaultNotesScreen(),
          ),
        ],
      ),
      _appRoute(
        path: RoutePaths.reminders,
        name: RouteNames.reminders,
        builder: (_, __) => const RemindersScreen(),
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
