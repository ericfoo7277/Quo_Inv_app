import '../../shared/models/payment.dart';
import 'mock_seed.dart';

/// Lightweight read-only repo for payments — full CRUD will land alongside
/// payment capture in a later phase.
class MockPaymentRepository {
  MockPaymentRepository() : _items = MockSeed.payments();

  final List<Payment> _items;

  static const _latency = Duration(milliseconds: 200);

  Future<List<Payment>> fetchAll() async {
    await Future.delayed(_latency);
    final sorted = [..._items]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  Future<Payment> create(Payment payment) async {
    await Future.delayed(_latency);
    _items.add(payment);
    return payment;
  }
}
