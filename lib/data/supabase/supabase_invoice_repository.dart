import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/invoice.dart';
import '../repositories/invoice_repository.dart';

/// Supabase-backed implementation of [InvoiceRepository].
///
/// Behaviour parity notes:
/// * Invoice numbers are allocated from business_profiles.invoice_prefix +
///   invoice_next_number on create.
/// * Line items live in invoice_items (cascade delete).
/// * `amount_paid` and `balance_due` are persisted on the invoice row and
///   updated by the payment repository when payments are recorded.
/// * `status = overdue` is computed at read-time when the stored status is
///   `sent` and the due date has passed with non-zero balance.
class SupabaseInvoiceRepository implements InvoiceRepository {
  SupabaseInvoiceRepository(this._client);

  final SupabaseClient _client;

  static const _invoices = 'invoices';
  static const _items = 'invoice_items';
  static const _profiles = 'business_profiles';
  static const _customers = 'customers';

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
  Future<List<Invoice>> fetchAll({
    InvoiceStatus? status,
    String? customerId,
    String? search,
  }) async {
    var query = _client
        .from(_invoices)
        .select('*, customers(name)')
        .eq('user_id', _uid);

    if (status != null && status != InvoiceStatus.overdue) {
      query = query.eq('status', _statusToDb(status));
    }
    if (customerId != null) query = query.eq('customer_id', customerId);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('invoice_number', '%$search%');
    }

    final rows =
        await query.order('issue_date', ascending: false) as List<dynamic>;

    final invoices = <Invoice>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'] as String;
      final items = await _fetchItems(id);
      invoices.add(_fromMap(map, items: items));
    }

    if (status == InvoiceStatus.overdue) {
      return invoices.where((i) => i.status == InvoiceStatus.overdue).toList();
    }
    return invoices;
  }

  @override
  Future<Invoice?> fetchById(String id) async {
    final data = await _client
        .from(_invoices)
        .select('*, customers(name)')
        .eq('user_id', _uid)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    final items = await _fetchItems(id);
    return _fromMap(data, items: items);
  }

  @override
  Stream<List<Invoice>> watchAll() {
    return _client
        .from(_invoices)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('issue_date', ascending: false)
        .asyncMap((rows) async {
      final maps = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      final customerNames = await _customerNamesById(
        maps.map((m) => m['customer_id'] as String).toSet(),
      );

      return maps.map((m) {
        final customerName = customerNames[m['customer_id'] as String];
        if (customerName != null) {
          m['customers'] = {'name': customerName};
        }
        return _fromMap(m, items: const []);
      }).toList(growable: false);
    });
  }

      Future<Map<String, String>> _customerNamesById(Set<String> ids) async {
        if (ids.isEmpty) return const {};

        final rows = await _client
            .from(_customers)
            .select('id, name')
            .eq('user_id', _uid)
            .inFilter('id', ids.toList()) as List<dynamic>;

        return {
          for (final row in rows)
            (row as Map)['id'] as String: (row['name'] as String?) ?? '',
        };
      }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<Invoice> create(Invoice invoice) async {
    final number = invoice.invoiceNumber.isEmpty
        ? await _allocateNumber()
        : invoice.invoiceNumber;

    final map = _toMap(invoice.copyWith(invoiceNumber: number))..remove('id');
    final inserted = await _client
        .from(_invoices)
        .insert(map)
        .select('*, customers(name)')
        .single();
    final newId = inserted['id'] as String;
    if (invoice.items.isNotEmpty) {
      await _replaceItems(newId, invoice.items);
    }
    final items = await _fetchItems(newId);
    return _fromMap(inserted, items: items);
  }

  @override
  Future<Invoice> update(Invoice invoice) async {
    final map = _toMap(invoice);
    final updated = await _client
        .from(_invoices)
        .update(map)
        .eq('user_id', _uid)
        .eq('id', invoice.id)
        .select('*, customers(name)')
        .single();
    await _replaceItems(invoice.id, invoice.items);
    final items = await _fetchItems(invoice.id);
    return _fromMap(updated, items: items);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_invoices).delete().eq('user_id', _uid).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  Future<List<InvoiceLineItem>> _fetchItems(String invoiceId) async {
    final rows = await _client
        .from(_items)
        .select()
        .eq('user_id', _uid)
        .eq('invoice_id', invoiceId)
        .order('sort_order', ascending: true) as List<dynamic>;
    return rows
        .map((r) => _itemFromMap(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  Future<void> _replaceItems(
    String invoiceId,
    List<InvoiceLineItem> items,
  ) async {
    await _client
        .from(_items)
        .delete()
        .eq('user_id', _uid)
        .eq('invoice_id', invoiceId);

    if (items.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add({
        'invoice_id': invoiceId,
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

  Future<String> _allocateNumber() async {
    final profile = await _client
        .from(_profiles)
        .select('invoice_prefix, invoice_next_number')
        .eq('user_id', _uid)
        .maybeSingle();

    final prefix = (profile?['invoice_prefix'] as String?) ?? 'INV-';
    final next = (profile?['invoice_next_number'] as int?) ?? 1;
    final number = '$prefix${next.toString().padLeft(4, '0')}';

    await _client.from(_profiles).update({
      'invoice_next_number': next + 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);

    return number;
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toMap(Invoice i) {
    final balance = (i.totalAmount - i.amountPaid).clamp(0, double.infinity);
    return {
      'id': i.id,
      'user_id': _uid,
      'customer_id': i.customerId,
      'source_quotation_id': i.sourceQuotationId,
      'invoice_number': i.invoiceNumber,
      'issue_date': _dateOnly(i.issueDate),
      'due_date': _dateOnly(i.dueDate),
      'currency': i.currency,
      'subtotal': i.subtotal,
      'discount_amount': i.discountAmount,
      'total_amount': i.totalAmount,
      'amount_paid': i.amountPaid,
      'balance_due': balance,
      'tax_rate': i.taxRate,
      'notes': i.notes,
      'payment_instructions': i.paymentInstructions,
      'status': _statusToDb(i.status),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Invoice _fromMap(
    Map<String, dynamic> m, {
    required List<InvoiceLineItem> items,
  }) {
    final customer = m['customers'];
    final customerName = customer is Map ? (customer['name'] as String?) : null;

    final dueDate = DateTime.parse(m['due_date'] as String);
    final amountPaid = (m['amount_paid'] as num?)?.toDouble() ?? 0;
    final total = (m['total_amount'] as num?)?.toDouble() ?? 0;
    final storedStatus = _statusFromDb(m['status'] as String?);

    // Compute "overdue" derived state without persisting it.
    InvoiceStatus effectiveStatus = storedStatus;
    final hasBalance = total - amountPaid > 0.005;
    final isPastDue = DateTime.now().isAfter(dueDate);
    if (storedStatus == InvoiceStatus.sent && hasBalance && isPastDue) {
      effectiveStatus = InvoiceStatus.overdue;
    } else if (storedStatus == InvoiceStatus.partiallyPaid &&
        hasBalance &&
        isPastDue) {
      effectiveStatus = InvoiceStatus.overdue;
    }

    return Invoice(
      id: m['id'] as String,
      userId: m['user_id'] as String?,
      invoiceNumber: m['invoice_number'] as String,
      customerId: m['customer_id'] as String,
      customerName: customerName ?? '',
      sourceQuotationId: m['source_quotation_id'] as String?,
      issueDate: DateTime.parse(m['issue_date'] as String),
      dueDate: dueDate,
      items: items,
      status: effectiveStatus,
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
      amountPaid: amountPaid,
      notes: m['notes'] as String?,
      paymentInstructions: m['payment_instructions'] as String?,
      currency: (m['currency'] as String?) ?? 'MYR',
      storedTotal: items.isEmpty ? (m['total_amount'] as num?)?.toDouble() : null,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
    );
  }

  InvoiceLineItem _itemFromMap(Map<String, dynamic> m) {
    return InvoiceLineItem(
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

  static String _statusToDb(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.sent:
        return 'sent';
      case InvoiceStatus.partiallyPaid:
        return 'partially_paid';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.overdue:
        // overdue is computed; persist as 'sent' so the underlying state is
        // recoverable if a payment later clears the balance.
        return 'sent';
      case InvoiceStatus.cancelled:
        return 'cancelled';
    }
  }

  static InvoiceStatus _statusFromDb(String? s) {
    switch (s) {
      case 'sent':
        return InvoiceStatus.sent;
      case 'partially_paid':
        return InvoiceStatus.partiallyPaid;
      case 'paid':
        return InvoiceStatus.paid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'draft':
      default:
        return InvoiceStatus.draft;
    }
  }
}
