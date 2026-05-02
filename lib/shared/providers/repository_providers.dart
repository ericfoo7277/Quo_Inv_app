import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/quotation_repository.dart';
import '../../data/repositories/user_device_repository.dart';
import '../../data/supabase/supabase_customer_repository.dart';
import '../../data/supabase/supabase_invoice_repository.dart';
import '../../data/supabase/supabase_payment_repository.dart';
import '../../data/supabase/supabase_quotation_repository.dart';
import '../../data/supabase/supabase_user_device_repository.dart';
import 'auth_providers.dart';

/// Repository wiring.
///
/// All four document repositories are backed by Supabase. The Supabase client
/// must be initialised in main.dart before any of these providers are read.
///
/// BusinessProfile and ReminderSetting providers live in their own dedicated
/// files: business_profile_provider.dart and reminder_setting_provider.dart.

SupabaseClient _requireClient(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase client is not configured. Ensure Supabase.initialize() ran '
      'with valid SUPABASE_URL and SUPABASE_ANON_KEY before reading any '
      'repository provider.',
    );
  }
  return client;
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository(_requireClient(ref));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return SupabaseInvoiceRepository(_requireClient(ref));
});

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return SupabaseQuotationRepository(
    _requireClient(ref),
    ref.watch(invoiceRepositoryProvider),
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(_requireClient(ref));
});

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  return SupabaseUserDeviceRepository(_requireClient(ref));
});
