import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_customer_repository.dart';
import '../../data/mock/mock_invoice_repository.dart';
import '../../data/mock/mock_payment_repository.dart';
import '../../data/mock/mock_quotation_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/quotation_repository.dart';

/// Repository wiring. Swap the implementations here when introducing
/// Supabase / Firebase — the rest of the app keeps consuming the abstract
/// interfaces unchanged.
///
/// Example (future):
/// ```dart
/// final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
///   return SupabaseInvoiceRepository(ref.watch(supabaseClientProvider));
/// });
/// ```
///
/// BusinessProfile and ReminderSetting providers live in their own dedicated
/// files: business_profile_provider.dart and reminder_setting_provider.dart.

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return MockCustomerRepository();
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return MockInvoiceRepository();
});

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return MockQuotationRepository(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
  );
});

final paymentRepositoryProvider = Provider<MockPaymentRepository>((ref) {
  return MockPaymentRepository();
});
