import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import 'repository_providers.dart';

final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchAll();
});
