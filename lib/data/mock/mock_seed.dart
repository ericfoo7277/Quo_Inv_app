import '../../shared/models/customer.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/payment.dart';
import '../../shared/models/quotation.dart';

/// Realistic seed data used by the mock repositories.
///
/// Centralised so different mock repos stay in sync (e.g. invoice.customerId
/// always matches an entry in [customers]).
class MockSeed {
  MockSeed._();

  static List<Customer> customers() => [
        Customer(
          id: 'cus_001',
          name: 'Aisha Khan',
          email: 'aisha@brightlabs.io',
          companyName: 'Bright Labs',
          phone: '+1 415 555 0142',
          billingAddress: '450 Mission St, San Francisco, CA',
          createdAt: DateTime(2025, 11, 4),
        ),
        Customer(
          id: 'cus_002',
          name: 'Lucas Müller',
          email: 'lucas@northwind.de',
          companyName: 'Northwind GmbH',
          phone: '+49 30 555 0184',
          billingAddress: 'Friedrichstraße 200, 10117 Berlin',
          createdAt: DateTime(2025, 12, 19),
        ),
        Customer(
          id: 'cus_003',
          name: 'Priya Sharma',
          email: 'priya@kavi.studio',
          companyName: 'Kavi Studio',
          phone: '+91 98 1010 0033',
          billingAddress: '12 MG Road, Bengaluru 560001',
          createdAt: DateTime(2026, 1, 8),
        ),
        Customer(
          id: 'cus_004',
          name: 'Diego Alvarez',
          email: 'diego@costa.mx',
          companyName: 'Costa Digital',
          phone: '+52 55 5555 0199',
          billingAddress: 'Av. Reforma 222, Mexico City',
          createdAt: DateTime(2026, 2, 11),
        ),
        Customer(
          id: 'cus_005',
          name: 'Sara Okonkwo',
          email: 'sara@lagoscreative.ng',
          companyName: 'Lagos Creative',
          phone: '+234 802 555 0123',
          billingAddress: '14 Awolowo Rd, Ikoyi, Lagos',
          createdAt: DateTime(2026, 3, 1),
        ),
        Customer(
          id: 'cus_006',
          name: 'Hiroshi Tanaka',
          email: 'hiroshi@kotori.jp',
          companyName: 'Kotori Co.',
          phone: '+81 3 5555 0177',
          billingAddress: '2-7-1 Marunouchi, Chiyoda, Tokyo',
          createdAt: DateTime(2026, 3, 22),
        ),
      ];

  static List<Invoice> invoices() => [
        Invoice(
          id: 'inv_001',
          invoiceNumber: 'INV-2026-001',
          customerId: 'cus_001',
          customerName: 'Aisha Khan',
          issueDate: DateTime(2026, 4, 1),
          dueDate: DateTime(2026, 4, 15),
          status: InvoiceStatus.paid,
          amountPaid: 2935.50,
          taxRate: 0.0875,
          items: const [
            InvoiceLineItem(
                description: 'Brand identity design',
                quantity: 1,
                unitPrice: 2400),
            InvoiceLineItem(
                description: 'Logo revisions', quantity: 3, unitPrice: 120),
          ],
        ),
        Invoice(
          id: 'inv_002',
          invoiceNumber: 'INV-2026-002',
          customerId: 'cus_002',
          customerName: 'Lucas Müller',
          currency: 'EUR',
          issueDate: DateTime(2026, 4, 10),
          dueDate: DateTime(2026, 4, 24),
          status: InvoiceStatus.sent,
          taxRate: 0.19,
          items: const [
            InvoiceLineItem(
                description: 'Web development sprint',
                quantity: 40,
                unitPrice: 85),
          ],
        ),
        Invoice(
          id: 'inv_003',
          invoiceNumber: 'INV-2026-003',
          customerId: 'cus_003',
          customerName: 'Priya Sharma',
          issueDate: DateTime(2026, 3, 12),
          dueDate: DateTime(2026, 3, 26),
          status: InvoiceStatus.overdue,
          taxRate: 0.18,
          items: const [
            InvoiceLineItem(
                description: 'Mobile app consulting',
                quantity: 8,
                unitPrice: 150),
          ],
        ),
        Invoice(
          id: 'inv_004',
          invoiceNumber: 'INV-2026-004',
          customerId: 'cus_004',
          customerName: 'Diego Alvarez',
          issueDate: DateTime(2026, 4, 22),
          dueDate: DateTime(2026, 5, 6),
          status: InvoiceStatus.draft,
          items: const [
            InvoiceLineItem(
                description: 'Marketing site redesign',
                quantity: 1,
                unitPrice: 4800),
          ],
        ),
        Invoice(
          id: 'inv_005',
          invoiceNumber: 'INV-2026-005',
          customerId: 'cus_005',
          customerName: 'Sara Okonkwo',
          issueDate: DateTime(2026, 4, 18),
          dueDate: DateTime(2026, 5, 2),
          status: InvoiceStatus.partiallyPaid,
          amountPaid: 650,
          items: const [
            InvoiceLineItem(
                description: 'Campaign copywriting',
                quantity: 12,
                unitPrice: 95),
            InvoiceLineItem(
                description: 'Social asset pack', quantity: 1, unitPrice: 650),
          ],
        ),
        Invoice(
          id: 'inv_006',
          invoiceNumber: 'INV-2026-006',
          customerId: 'cus_001',
          customerName: 'Aisha Khan',
          issueDate: DateTime(2026, 4, 20),
          dueDate: DateTime(2026, 5, 4),
          status: InvoiceStatus.paid,
          amountPaid: 1957.50,
          taxRate: 0.0875,
          items: const [
            InvoiceLineItem(
                description: 'Design retainer — April',
                quantity: 1,
                unitPrice: 1800),
          ],
        ),
        Invoice(
          id: 'inv_007',
          invoiceNumber: 'INV-2026-007',
          customerId: 'cus_006',
          customerName: 'Hiroshi Tanaka',
          currency: 'JPY',
          issueDate: DateTime(2026, 4, 23),
          dueDate: DateTime(2026, 5, 7),
          status: InvoiceStatus.draft,
          items: const [
            InvoiceLineItem(
                description: 'Translation services',
                quantity: 20,
                unitPrice: 4200),
          ],
        ),
      ];

  static List<Quotation> quotations() => [
        Quotation(
          id: 'quo_001',
          quotationNumber: 'QUO-2026-001',
          customerId: 'cus_001',
          customerName: 'Aisha Khan',
          issueDate: DateTime(2026, 4, 5),
          validUntil: DateTime(2026, 5, 5),
          status: QuotationStatus.accepted,
          items: const [
            QuotationLineItem(
                description: 'Design system foundation',
                quantity: 1,
                unitPrice: 5200),
          ],
        ),
        Quotation(
          id: 'quo_002',
          quotationNumber: 'QUO-2026-002',
          customerId: 'cus_002',
          customerName: 'Lucas Müller',
          currency: 'EUR',
          issueDate: DateTime(2026, 4, 18),
          validUntil: DateTime(2026, 5, 18),
          status: QuotationStatus.sent,
          taxRate: 0.19,
          items: const [
            QuotationLineItem(
                description: 'API integration', quantity: 30, unitPrice: 90),
          ],
        ),
        Quotation(
          id: 'quo_003',
          quotationNumber: 'QUO-2026-003',
          customerId: 'cus_004',
          customerName: 'Diego Alvarez',
          issueDate: DateTime(2026, 3, 28),
          validUntil: DateTime(2026, 4, 28),
          status: QuotationStatus.expired,
          items: const [
            QuotationLineItem(
                description: 'Landing page', quantity: 1, unitPrice: 1800),
          ],
        ),
        Quotation(
          id: 'quo_004',
          quotationNumber: 'QUO-2026-004',
          customerId: 'cus_005',
          customerName: 'Sara Okonkwo',
          issueDate: DateTime(2026, 4, 21),
          validUntil: DateTime(2026, 5, 21),
          status: QuotationStatus.draft,
          items: const [
            QuotationLineItem(
                description: 'Brand workshop', quantity: 1, unitPrice: 2200),
            QuotationLineItem(
                description: 'Visual exploration',
                quantity: 1,
                unitPrice: 1400),
          ],
        ),
        Quotation(
          id: 'quo_005',
          quotationNumber: 'QUO-2026-005',
          customerId: 'cus_003',
          customerName: 'Priya Sharma',
          issueDate: DateTime(2026, 4, 12),
          validUntil: DateTime(2026, 5, 12),
          status: QuotationStatus.declined,
          items: const [
            QuotationLineItem(
                description: 'iOS prototype', quantity: 1, unitPrice: 3600),
          ],
        ),
      ];

  static List<Payment> payments() => [
        Payment(
          id: 'pay_001',
          invoiceId: 'inv_001',
          invoiceNumber: 'INV-2026-001',
          customerName: 'Aisha Khan',
          amount: 2935.50,
          paymentDate: DateTime(2026, 4, 14),
          paymentMethod: PaymentMethod.card,
        ),
        Payment(
          id: 'pay_002',
          invoiceId: 'inv_006',
          invoiceNumber: 'INV-2026-006',
          customerName: 'Aisha Khan',
          amount: 1957.50,
          paymentDate: DateTime(2026, 4, 24),
          paymentMethod: PaymentMethod.bank,
        ),
      ];
}
