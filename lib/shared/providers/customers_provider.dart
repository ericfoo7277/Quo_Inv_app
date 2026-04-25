import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import 'repository_providers.dart';

/// All customers, reactively bound to the repository's stream.
final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAll();
});

/// One customer by id.
final customerByIdProvider =
    FutureProvider.family<Customer?, String>((ref, id) {
  // React to repository changes so detail screens refresh after edits.
  ref.watch(customersProvider);
  return ref.watch(customerRepositoryProvider).fetchById(id);
});
