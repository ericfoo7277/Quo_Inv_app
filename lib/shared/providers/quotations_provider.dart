import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quotation.dart';
import 'repository_providers.dart';

final quotationsProvider = StreamProvider<List<Quotation>>((ref) {
  return ref.watch(quotationRepositoryProvider).watchAll();
});

final quotationByIdProvider =
    FutureProvider.family<Quotation?, String>((ref, id) {
  ref.watch(quotationsProvider);
  return ref.watch(quotationRepositoryProvider).fetchById(id);
});

final quotationsByCustomerProvider =
    FutureProvider.family<List<Quotation>, String>((ref, customerId) {
  ref.watch(quotationsProvider);
  return ref
      .watch(quotationRepositoryProvider)
      .fetchAll(customerId: customerId);
});
