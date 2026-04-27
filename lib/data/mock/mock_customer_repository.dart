import 'dart:async';

import '../../shared/models/customer.dart';
import '../repositories/customer_repository.dart';
import 'mock_seed.dart';

/// In-memory mock implementation. Simulates a small network latency so the
/// UI gets to exercise its loading states.
class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository() {
    _items = MockSeed.customers();
  }

  late List<Customer> _items;
  final _controller = StreamController<List<Customer>>.broadcast();

  static const _latency = Duration(milliseconds: 250);

  void _emit() => _controller.add(List.unmodifiable(_items));

  @override
  Future<List<Customer>> fetchAll({String? search}) async {
    await Future.delayed(_latency);
    if (search == null || search.isEmpty) return List.unmodifiable(_items);
    final q = search.toLowerCase();
    return _items
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            (c.companyName?.toLowerCase().contains(q) ?? false))
        .toList(growable: false);
  }

  @override
  Future<Customer?> fetchById(String id) async {
    await Future.delayed(_latency);
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<Customer> create(Customer customer) async {
    await Future.delayed(_latency);
    final created = customer.id.isEmpty
        ? customer.copyWith(
            id: 'cus_${DateTime.now().microsecondsSinceEpoch}',
            createdAt: DateTime.now(),
          )
        : customer;
    _items = [..._items, created];
    _emit();
    return created;
  }

  @override
  Future<Customer> update(Customer customer) async {
    await Future.delayed(_latency);
    _items = [
      for (final c in _items)
        if (c.id == customer.id) customer else c,
    ];
    _emit();
    return customer;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(_latency);
    _items = _items.where((c) => c.id != id).toList(growable: false);
    _emit();
  }

  @override
  Stream<List<Customer>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }
}
