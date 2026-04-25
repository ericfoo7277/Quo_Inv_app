import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import 'repository_providers.dart';

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchAll();
});

final invoiceByIdProvider = FutureProvider.family<Invoice?, String>((ref, id) {
  ref.watch(invoicesProvider);
  return ref.watch(invoiceRepositoryProvider).fetchById(id);
});

/// Invoices belonging to a single customer (sorted newest first).
final invoicesByCustomerProvider =
    FutureProvider.family<List<Invoice>, String>((ref, customerId) {
  ref.watch(invoicesProvider);
  return ref.watch(invoiceRepositoryProvider).fetchAll(customerId: customerId);
});
