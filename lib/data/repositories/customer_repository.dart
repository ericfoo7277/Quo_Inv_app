import '../../shared/models/customer.dart';

/// Repository contract for customer persistence.
///
/// The mock implementation lives in [MockCustomerRepository]. A future
/// `SupabaseCustomerRepository` (or Firebase variant) implements this same
/// interface so the rest of the app keeps working unchanged.
abstract class CustomerRepository {
  /// Returns customers, optionally filtered by [search] and including
  /// archived rows when [includeArchived] is true. Archived customers
  /// are hidden from default lists.
  Future<List<Customer>> fetchAll({String? search, bool includeArchived = false});
  Future<Customer?> fetchById(String id);
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);

  /// Soft-deletes the customer by setting `is_archived = true`.
  Future<void> archive(String id);

  /// Restores a previously archived customer.
  Future<void> restore(String id);

  /// Hard-deletes the customer record. Use with care — invoices and
  /// quotations referencing this customer will fail FK constraints
  /// unless they're deleted first.
  Future<void> delete(String id);

  /// Live updates. Mock impl emits whenever the in-memory list changes;
  /// Supabase impl will bind to a realtime channel.
  Stream<List<Customer>> watchAll();
}
