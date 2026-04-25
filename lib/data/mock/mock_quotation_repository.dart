import 'dart:async';

import '../../shared/models/invoice.dart';
import '../../shared/models/quotation.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/quotation_repository.dart';
import 'mock_seed.dart';

class MockQuotationRepository implements QuotationRepository {
  MockQuotationRepository({required InvoiceRepository invoiceRepository})
      : _invoiceRepository = invoiceRepository {
    _items = MockSeed.quotations();
  }

  final InvoiceRepository _invoiceRepository;
  late List<Quotation> _items;
  final _controller = StreamController<List<Quotation>>.broadcast();

  static const _latency = Duration(milliseconds: 250);

  void _emit() => _controller.add(List.unmodifiable(_items));

  @override
  Future<List<Quotation>> fetchAll({
    QuotationStatus? status,
    String? customerId,
    String? search,
  }) async {
    await Future.delayed(_latency);
    Iterable<Quotation> result = _items;
    if (status != null) result = result.where((q) => q.status == status);
    if (customerId != null) {
      result = result.where((q) => q.customerId == customerId);
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      result = result.where((q) =>
          q.number.toLowerCase().contains(s) ||
          q.customerName.toLowerCase().contains(s));
    }
    final sorted = result.toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Quotation?> fetchById(String id) async {
    await Future.delayed(_latency);
    for (final q in _items) {
      if (q.id == id) return q;
    }
    return null;
  }

  @override
  Future<Quotation> create(Quotation quotation) async {
    await Future.delayed(_latency);
    final created = quotation.id.isEmpty
        ? quotation.copyWith(id: 'quo_${DateTime.now().microsecondsSinceEpoch}')
        : quotation;
    _items = [..._items, created];
    _emit();
    return created;
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    await Future.delayed(_latency);
    _items = [
      for (final q in _items)
        if (q.id == quotation.id) quotation else q,
    ];
    _emit();
    return quotation;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(_latency);
    _items = _items.where((q) => q.id != id).toList(growable: false);
    _emit();
  }

  @override
  Future<String> convertToInvoice(String quotationId) async {
    final q = await fetchById(quotationId);
    if (q == null) {
      throw StateError('Quotation $quotationId not found');
    }
    final invoice = Invoice(
      id: '',
      number:
          'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.remainder(10000)}',
      customerId: q.customerId,
      customerName: q.customerName,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      items: q.items
          .map((i) => InvoiceLineItem(
                description: i.description,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
              ))
          .toList(growable: false),
      status: InvoiceStatus.draft,
      taxRate: q.taxRate,
      currency: q.currency,
      notes: q.notes,
    );
    final created = await _invoiceRepository.create(invoice);
    return created.id;
  }

  @override
  Stream<List<Quotation>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }
}
