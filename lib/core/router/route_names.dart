/// Centralized route name + path constants for go_router.
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String businessSetup = 'business-setup';

  static const String dashboard = 'dashboard';

  static const String invoices = 'invoices';
  static const String invoiceDetail = 'invoice-detail';
  static const String invoiceForm = 'invoice-form';
  static const String invoiceEdit = 'invoice-edit';

  static const String quotations = 'quotations';
  static const String quotationDetail = 'quotation-detail';
  static const String quotationForm = 'quotation-form';
  static const String quotationEdit = 'quotation-edit';

  static const String customers = 'customers';
  static const String customerDetail = 'customer-detail';
  static const String customerForm = 'customer-form';
  static const String customerEdit = 'customer-edit';

  static const String payments = 'payments';
  static const String settings = 'settings';
  static const String profile = 'profile';

  static const String reminders = 'reminders';
  static const String businessProfile = 'business-profile';
  static const String numberingSettings = 'numbering-settings';
  static const String reminderSettings = 'reminder-settings';
  static const String defaultNotes = 'default-notes';
}

class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String businessSetup = '/business-setup';

  static const String dashboard = '/dashboard';

  static const String invoices = '/invoices';
  static String invoiceDetail(String id) => '/invoices/$id';
  static const String invoiceForm = '/invoices/new';
  static const String invoiceEdit = '/invoices/:id/edit';

  static const String quotations = '/quotations';
  static String quotationDetail(String id) => '/quotations/$id';
  static const String quotationForm = '/quotations/new';
  static const String quotationEdit = '/quotations/:id/edit';

  static const String customers = '/customers';
  static String customerDetail(String id) => '/customers/$id';
  static const String customerForm = '/customers/new';
  static const String customerEdit = '/customers/:id/edit';

  static const String payments = '/payments';
  static const String settings = '/settings';
  static const String profile = '/settings/profile';

  static const String reminders = '/reminders';
  static const String businessProfile = '/settings/business-profile';
  static const String numberingSettings = '/settings/numbering';
  static const String reminderSettings = '/settings/reminders';
  static const String defaultNotes = '/settings/default-notes';
}
