import '../../shared/models/customer.dart';

/// Repository contract for customer persistence.
///
/// The mock implementation lives in [MockCustomerRepository]. A future
/// `SupabaseCustomerRepository` (or Firebase variant) implements this same
/// interface so the rest of the app keeps working unchanged.
abstract class CustomerRepository {
  Future<List<Customer>> fetchAll({String? search});
  Future<Customer?> fetchById(String id);
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<void> delete(String id);

  /// Live updates. Mock impl emits whenever the in-memory list changes;
  /// Supabase impl will bind to a realtime channel.
  Stream<List<Customer>> watchAll();
}
