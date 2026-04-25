import '../../shared/models/quotation.dart';

abstract class QuotationRepository {
  Future<List<Quotation>> fetchAll({
    QuotationStatus? status,
    String? customerId,
    String? search,
  });

  Future<Quotation?> fetchById(String id);
  Future<Quotation> create(Quotation quotation);
  Future<Quotation> update(Quotation quotation);
  Future<void> delete(String id);

  /// Convert an accepted quotation into a draft invoice. Useful as a single
  /// atomic call once a real backend can run it server-side.
  Future<String> convertToInvoice(String quotationId);

  Stream<List<Quotation>> watchAll();
}
