import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/payment.dart';
import '../repositories/payment_repository.dart';

/// Supabase-backed implementation of [PaymentRepository].
///
/// On create / delete this repository also updates the parent invoice's
/// amount_paid, balance_due and status fields so list views stay in sync
/// without needing a separate refresh.
class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this._client);

  final SupabaseClient _client;

  static const _payments = 'payments';
  static const _invoices = 'invoices';

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
  Future<List<Payment>> fetchAll() async {
    final rows = await _client
        .from(_payments)
        .select('*, invoices(invoice_number, customers(name))')
        .eq('user_id', _uid)
        .order('payment_date', ascending: false) as List<dynamic>;
    return rows
        .map((r) => _fromMap(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  @override
  Future<List<Payment>> fetchByInvoice(String invoiceId) async {
    final rows = await _client
        .from(_payments)
        .select('*, invoices(invoice_number, customers(name))')
        .eq('user_id', _uid)
        .eq('invoice_id', invoiceId)
        .order('payment_date', ascending: false) as List<dynamic>;
    return rows
        .map((r) => _fromMap(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<Payment> create(Payment payment) async {
    final map = {
      'user_id': _uid,
      'invoice_id': payment.invoiceId,
      'amount': payment.amount,
      'payment_date': _dateOnly(payment.paymentDate),
      'payment_method': _methodToDb(payment.paymentMethod),
      'reference_note': payment.referenceNote,
    };
    final inserted = await _client
        .from(_payments)
        .insert(map)
        .select('*, invoices(invoice_number, customers(name))')
        .single();

    await _refreshInvoiceTotals(payment.invoiceId);

    return _fromMap(inserted);
  }

  @override
  Future<void> delete(String id) async {
    final row = await _client
        .from(_payments)
        .select('invoice_id')
        .eq('user_id', _uid)
        .eq('id', id)
        .maybeSingle();

    await _client
        .from(_payments)
        .delete()
        .eq('user_id', _uid)
        .eq('id', id);

    final invoiceId = row?['invoice_id'] as String?;
    if (invoiceId != null) {
      await _refreshInvoiceTotals(invoiceId);
    }
  }

  // ---------------------------------------------------------------------------
  // Invoice totals refresh
  // ---------------------------------------------------------------------------

  /// Sums all payments for [invoiceId] and updates the parent invoice's
  /// amount_paid, balance_due and status accordingly.
  Future<void> _refreshInvoiceTotals(String invoiceId) async {
    final invoice = await _client
        .from(_invoices)
        .select('total_amount, status')
        .eq('user_id', _uid)
        .eq('id', invoiceId)
        .maybeSingle();
    if (invoice == null) return;

    final total = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
    final currentStatus = invoice['status'] as String? ?? 'draft';

    final paidRows = await _client
        .from(_payments)
        .select('amount')
        .eq('user_id', _uid)
        .eq('invoice_id', invoiceId) as List<dynamic>;

    final amountPaid = paidRows.fold<double>(
      0,
      (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0),
    );
    final balance =
        (total - amountPaid).clamp(0, double.infinity).toDouble();

    String newStatus;
    if (balance <= 0.005 && total > 0) {
      newStatus = 'paid';
    } else if (amountPaid > 0.005) {
      newStatus = 'partially_paid';
    } else if (currentStatus == 'paid' || currentStatus == 'partially_paid') {
      // Payment removed; revert to sent so list views show it as outstanding.
      newStatus = 'sent';
    } else {
      newStatus = currentStatus;
    }

    await _client
        .from(_invoices)
        .update({
          'amount_paid': amountPaid,
          'balance_due': balance,
          'status': newStatus,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('id', invoiceId);
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  Payment _fromMap(Map<String, dynamic> m) {
    final invoice = m['invoices'];
    String? invoiceNumber;
    String? customerName;
    if (invoice is Map) {
      invoiceNumber = invoice['invoice_number'] as String?;
      final customer = invoice['customers'];
      if (customer is Map) customerName = customer['name'] as String?;
    }

    return Payment(
      id: m['id'] as String,
      userId: m['user_id'] as String?,
      invoiceId: m['invoice_id'] as String,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      amount: (m['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(m['payment_date'] as String),
      paymentMethod: _methodFromDb(m['payment_method'] as String?),
      referenceNote: m['reference_note'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _methodToDb(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bank:
        return 'bank';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod _methodFromDb(String? m) {
    switch (m) {
      case 'card':
        return PaymentMethod.card;
      case 'cash':
        return PaymentMethod.cash;
      case 'bank':
        return PaymentMethod.bank;
      case 'other':
      default:
        return PaymentMethod.other;
    }
  }
}
