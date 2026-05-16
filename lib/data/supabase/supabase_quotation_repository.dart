import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/invoice.dart';
import '../../shared/models/quotation.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/quotation_repository.dart';

/// Supabase-backed implementation of [QuotationRepository].
///
/// Handles:
/// * Auto-numbering using business_profiles.quotation_prefix +
///   quotation_next_number, with the counter incremented on create.
/// * Line items in the quotation_items child table.
/// * Conversion to invoice (delegates to [InvoiceRepository.create] so the
///   invoice gets its own auto-number from invoice_next_number).
class SupabaseQuotationRepository implements QuotationRepository {
  SupabaseQuotationRepository(this._client, this._invoiceRepository);

  final SupabaseClient _client;
  final InvoiceRepository _invoiceRepository;

  static const _quotations = 'quotations';
  static const _items = 'quotation_items';
  static const _profiles = 'business_profiles';

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  Future<List<Quotation>> fetchAll({
    QuotationStatus? status,
    String? customerId,
    String? search,
  }) async {
    var query = _client
        .from(_quotations)
        .select('*, customers(name)')
        .eq('user_id', _uid);

    if (status != null) query = query.eq('status', _statusToDb(status));
    if (customerId != null) query = query.eq('customer_id', customerId);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('quotation_number', '%$search%');
    }

    final rows =
        await query.order('issue_date', ascending: false) as List<dynamic>;

    final quotations = <Quotation>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'] as String;
      final items = await _fetchItems(id);
      quotations.add(_fromMap(map, items: items));
    }
    return quotations;
  }

  @override
  Future<Quotation?> fetchById(String id) async {
    final data = await _client
        .from(_quotations)
        .select('*, customers(name)')
        .eq('user_id', _uid)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    final items = await _fetchItems(id);
    return _fromMap(data, items: items);
  }

  @override
  Stream<List<Quotation>> watchAll() {
    // Realtime stream of headers; items are loaded per-row on demand.
    return _client
        .from(_quotations)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('issue_date', ascending: false)
        .map((rows) => rows
            .map((r) => _fromMap(Map<String, dynamic>.from(r), items: const []))
            .toList(growable: false));
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<Quotation> create(Quotation quotation) async {
    final number = quotation.quotationNumber.isEmpty
        ? await _allocateNumber()
        : quotation.quotationNumber;

    final headerMap = _toMap(quotation.copyWith(quotationNumber: number))
      ..remove('id');

    final inserted = await _client
        .from(_quotations)
        .insert(headerMap)
        .select('*, customers(name)')
        .single();

    final newId = inserted['id'] as String;
    if (quotation.items.isNotEmpty) {
      await _replaceItems(newId, quotation.items);
    }
    final items = await _fetchItems(newId);
    return _fromMap(inserted, items: items);
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    final headerMap = _toMap(quotation);
    final updated = await _client
        .from(_quotations)
        .update(headerMap)
        .eq('user_id', _uid)
        .eq('id', quotation.id)
        .select('*, customers(name)')
        .single();
    await _replaceItems(quotation.id, quotation.items);
    final items = await _fetchItems(quotation.id);
    return _fromMap(updated, items: items);
  }

  @override
  Future<void> delete(String id) async {
    // quotation_items has ON DELETE CASCADE, so removing the parent is enough.
    await _client.from(_quotations).delete().eq('user_id', _uid).eq('id', id);
  }

  @override
  Future<String> convertToInvoice(String quotationId) async {
    final q = await fetchById(quotationId);
    if (q == null) {
      throw StateError('Quotation $quotationId not found');
    }
    final invoice = Invoice(
      id: '',
      invoiceNumber: '', // invoice repo allocates next number
      customerId: q.customerId,
      customerName: q.customerName,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      sourceQuotationId: q.id,
      items: q.items
          .map((i) => InvoiceLineItem(
                itemName: i.itemName,
                description: i.description,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                sortOrder: i.sortOrder,
              ))
          .toList(growable: false),
      status: InvoiceStatus.draft,
      taxRate: q.taxRate,
      discountAmount: q.discountAmount,
      currency: q.currency,
      notes: q.notes,
      paymentInstructions: q.paymentInstructions,
    );
    final created = await _invoiceRepository.create(invoice);

    // Link the quotation back to the new invoice and mark it as accepted.
    await _client
        .from(_quotations)
        .update({
          'converted_invoice_id': created.id,
          'status': 'accepted',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('id', q.id);

    return created.id;
  }

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  Future<List<QuotationLineItem>> _fetchItems(String quotationId) async {
    final rows = await _client
        .from(_items)
        .select()
        .eq('user_id', _uid)
        .eq('quotation_id', quotationId)
        .order('sort_order', ascending: true) as List<dynamic>;
    return rows
        .map((r) => _itemFromMap(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  /// Replace strategy: delete all existing items, then re-insert. Simpler
  /// than diffing and acceptable for typical document sizes.
  Future<void> _replaceItems(
    String quotationId,
    List<QuotationLineItem> items,
  ) async {
    await _client
        .from(_items)
        .delete()
        .eq('user_id', _uid)
        .eq('quotation_id', quotationId);

    if (items.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add({
        'quotation_id': quotationId,
        'user_id': _uid,
        'item_name': item.itemName,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'line_total': item.lineTotal,
        'sort_order': item.sortOrder == 0 ? i : item.sortOrder,
      });
    }
    await _client.from(_items).insert(rows);
  }

  // ---------------------------------------------------------------------------
  // Auto-numbering
  // ---------------------------------------------------------------------------

  /// Reads the user's quotation_prefix + quotation_next_number, formats the
  /// number, and increments the counter. Not strictly atomic but acceptable
  /// for single-user usage; the unique(user_id, quotation_number) constraint
  /// guards against collisions.
  Future<String> _allocateNumber() async {
    final profile = await _client
        .from(_profiles)
        .select('quotation_prefix, quotation_next_number')
        .eq('user_id', _uid)
        .maybeSingle();

    final prefix = (profile?['quotation_prefix'] as String?) ?? 'Q-';
    final next = (profile?['quotation_next_number'] as int?) ?? 1;
    final number = '$prefix${next.toString().padLeft(4, '0')}';

    await _client.from(_profiles).update({
      'quotation_next_number': next + 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);

    return number;
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toMap(Quotation q) => {
        'id': q.id,
        'user_id': _uid,
        'customer_id': q.customerId,
        'quotation_number': q.quotationNumber,
        'issue_date': _dateOnly(q.issueDate),
        'valid_until': _dateOnly(q.validUntil),
        'currency': q.currency,
        'subtotal': q.subtotal,
        'discount_amount': q.discountAmount,
        'tax_rate': q.taxRate,
        'total_amount': q.totalAmount,
        'notes': q.notes,
        'payment_instructions': q.paymentInstructions,
        'status': _statusToDb(q.status),
        'converted_invoice_id': q.convertedInvoiceId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Quotation _fromMap(
    Map<String, dynamic> m, {
    required List<QuotationLineItem> items,
  }) {
    final customer = m['customers'];
    final customerName = customer is Map ? (customer['name'] as String?) : null;
    return Quotation(
      id: m['id'] as String,
      userId: m['user_id'] as String?,
      quotationNumber: m['quotation_number'] as String,
      customerId: m['customer_id'] as String,
      customerName: customerName ?? '',
      issueDate: DateTime.parse(m['issue_date'] as String),
      validUntil: m['valid_until'] != null
          ? DateTime.parse(m['valid_until'] as String)
          : DateTime.parse(m['issue_date'] as String),
      items: items,
      status: _statusFromDb(m['status'] as String?),
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
      notes: m['notes'] as String?,
      paymentInstructions: m['payment_instructions'] as String?,
      convertedInvoiceId: m['converted_invoice_id'] as String?,
      currency: (m['currency'] as String?) ?? 'MYR',
      storedTotal: items.isEmpty ? (m['total_amount'] as num?)?.toDouble() : null,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
    );
  }

  QuotationLineItem _itemFromMap(Map<String, dynamic> m) {
    return QuotationLineItem(
      id: m['id'] as String?,
      itemName: m['item_name'] as String,
      description: m['description'] as String?,
      quantity: (m['quantity'] as num).toDouble(),
      unitPrice: (m['unit_price'] as num).toDouble(),
      sortOrder: (m['sort_order'] as int?) ?? 0,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _statusToDb(QuotationStatus s) {
    switch (s) {
      case QuotationStatus.draft:
        return 'draft';
      case QuotationStatus.sent:
        return 'sent';
      case QuotationStatus.accepted:
        return 'accepted';
      case QuotationStatus.declined:
        return 'declined';
      case QuotationStatus.expired:
        return 'expired';
    }
  }

  static QuotationStatus _statusFromDb(String? s) {
    switch (s) {
      case 'sent':
        return QuotationStatus.sent;
      case 'accepted':
        return QuotationStatus.accepted;
      case 'declined':
        return QuotationStatus.declined;
      case 'expired':
        return QuotationStatus.expired;
      case 'draft':
      default:
        return QuotationStatus.draft;
    }
  }
}
