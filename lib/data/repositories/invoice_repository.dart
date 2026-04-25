import '../../shared/models/invoice.dart';

/// Repository contract for invoice persistence.
///
/// Implementations: [MockInvoiceRepository] today, Supabase / Firebase
/// adapters in the future. Methods are async-first to keep network parity.
abstract class InvoiceRepository {
  Future<List<Invoice>> fetchAll({
    InvoiceStatus? status,
    String? customerId,
    String? search,
  });

  Future<Invoice?> fetchById(String id);
  Future<Invoice> create(Invoice invoice);
  Future<Invoice> update(Invoice invoice);
  Future<void> delete(String id);

  Stream<List<Invoice>> watchAll();
}
