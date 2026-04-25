enum PaymentMethod { card, bank, cash, other }

class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.method,
  });

  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
}
