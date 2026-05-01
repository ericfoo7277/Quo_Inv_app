import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/customer.dart';
import '../repositories/customer_repository.dart';

/// Supabase-backed implementation of [CustomerRepository].
///
/// All rows are scoped by `user_id = auth.uid()`. RLS on the customers
/// table also enforces this server-side.
class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'customers';

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  @override
  Future<List<Customer>> fetchAll({
    String? search,
    bool includeArchived = false,
  }) async {
    var query = _client.from(_table).select().eq('user_id', _uid);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    if (search != null && search.isNotEmpty) {
      // Match name, company, or email (case-insensitive).
      final term = '%$search%';
      query = query.or(
        'name.ilike.$term,company_name.ilike.$term,email.ilike.$term',
      );
    }

    final rows =
        await query.order('created_at', ascending: false) as List<dynamic>;
    return rows
        .map((r) => _fromMap(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  @override
  Future<Customer?> fetchById(String id) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _uid)
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : _fromMap(data);
  }

  @override
  Future<Customer> create(Customer customer) async {
    final map = _toMap(customer)..remove('id'); // let Postgres generate uuid
    final data =
        await _client.from(_table).insert(map).select().single();
    return _fromMap(data);
  }

  @override
  Future<Customer> update(Customer customer) async {
    final map = _toMap(customer);
    final data = await _client
        .from(_table)
        .update(map)
        .eq('user_id', _uid)
        .eq('id', customer.id)
        .select()
        .single();
    return _fromMap(data);
  }

  @override
  Future<void> archive(String id) async {
    await _client
        .from(_table)
        .update({
          'is_archived': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('id', id);
  }

  @override
  Future<void> restore(String id) async {
    await _client
        .from(_table)
        .update({
          'is_archived': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('user_id', _uid).eq('id', id);
  }

  @override
  Stream<List<Customer>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['is_archived'] != true)
            .map((r) => _fromMap(Map<String, dynamic>.from(r)))
            .toList(growable: false));
  }

  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toMap(Customer c) => {
        'id': c.id,
        'user_id': _uid,
        'name': c.name,
        'company_name': c.companyName,
        'phone': c.phone,
        'whatsapp_number': c.whatsappNumber,
        'email': c.email,
        'billing_address': c.billingAddress,
        'notes': c.notes,
        'is_archived': c.isArchived,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Customer _fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        name: m['name'] as String,
        companyName: m['company_name'] as String?,
        phone: m['phone'] as String?,
        whatsappNumber: m['whatsapp_number'] as String?,
        email: m['email'] as String?,
        billingAddress: m['billing_address'] as String?,
        notes: m['notes'] as String?,
        isArchived: (m['is_archived'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
      );
}
