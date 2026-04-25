/// Payment method options.
enum PaymentMethod { card, bank, cash, other }

/// A payment record against an invoice.
///
/// Schema: payments(id, user_id, invoice_id, amount, payment_date,
///   payment_method, reference_note, created_at)
class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.userId,
    this.invoiceNumber,
    this.customerName,
    this.referenceNote,
    this.createdAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  final String invoiceId;

  /// Denormalised for quick list rendering. Not stored in schema.
  final String? invoiceNumber;

  /// Denormalised for quick list rendering. Not stored in schema.
  final String? customerName;

  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? referenceNote;
  final DateTime? createdAt;
}
