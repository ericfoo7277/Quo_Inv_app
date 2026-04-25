/// Centralized route name + path constants for go_router.
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';

  static const String dashboard = 'dashboard';

  static const String invoices = 'invoices';
  static const String invoiceDetail = 'invoice-detail';

  static const String quotations = 'quotations';
  static const String quotationDetail = 'quotation-detail';

  static const String customers = 'customers';
  static const String customerDetail = 'customer-detail';

  static const String payments = 'payments';
  static const String settings = 'settings';
}

class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  static const String dashboard = '/dashboard';

  static const String invoices = '/invoices';
  static String invoiceDetail(String id) => '/invoices/$id';

  static const String quotations = '/quotations';
  static String quotationDetail(String id) => '/quotations/$id';

  static const String customers = '/customers';
  static String customerDetail(String id) => '/customers/$id';

  static const String payments = '/payments';
  static const String settings = '/settings';
}
