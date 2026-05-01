import '../../shared/models/payment.dart';

/// Repository contract for payment persistence.
///
/// Implementations: [MockPaymentRepository] today, Supabase adapter for
/// real backend usage. Recording a payment is expected to atomically:
/// 1. Insert a row in payments.
/// 2. Update the parent invoice's amount_paid, balance_due and status
///    (`paid` when balance reaches 0, `partially_paid` otherwise).
abstract class PaymentRepository {
  /// All payments across all invoices, newest first.
  Future<List<Payment>> fetchAll();

  /// All payments for a single invoice, newest first.
  Future<List<Payment>> fetchByInvoice(String invoiceId);

  /// Records a payment and updates the parent invoice totals.
  Future<Payment> create(Payment payment);

  /// Removes a payment row and refreshes the parent invoice totals.
  Future<void> delete(String id);
}
