import 'dart:async';

import '../../shared/models/invoice.dart';
import '../repositories/invoice_repository.dart';
import 'mock_seed.dart';

class MockInvoiceRepository implements InvoiceRepository {
  MockInvoiceRepository() {
    _items = MockSeed.invoices();
  }

  late List<Invoice> _items;
  final _controller = StreamController<List<Invoice>>.broadcast();

  static const _latency = Duration(milliseconds: 250);

  void _emit() => _controller.add(List.unmodifiable(_items));

  @override
  Future<List<Invoice>> fetchAll({
    InvoiceStatus? status,
    String? customerId,
    String? search,
  }) async {
    await Future.delayed(_latency);
    Iterable<Invoice> result = _items;
    if (status != null) result = result.where((i) => i.status == status);
    if (customerId != null) {
      result = result.where((i) => i.customerId == customerId);
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((i) =>
          i.invoiceNumber.toLowerCase().contains(q) ||
          i.customerName.toLowerCase().contains(q));
    }
    final sorted = result.toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Invoice?> fetchById(String id) async {
    await Future.delayed(_latency);
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<Invoice> create(Invoice invoice) async {
    await Future.delayed(_latency);
    final created = invoice.id.isEmpty
        ? invoice.copyWith(id: 'inv_${DateTime.now().microsecondsSinceEpoch}')
        : invoice;
    _items = [..._items, created];
    _emit();
    return created;
  }

  @override
  Future<Invoice> update(Invoice invoice) async {
    await Future.delayed(_latency);
    _items = [
      for (final i in _items)
        if (i.id == invoice.id) invoice else i,
    ];
    _emit();
    return invoice;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(_latency);
    _items = _items.where((i) => i.id != id).toList(growable: false);
    _emit();
  }

  @override
  Stream<List<Invoice>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }
}
