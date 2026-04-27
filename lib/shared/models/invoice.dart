import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum InvoiceStatus { draft, sent, partiallyPaid, paid, overdue, cancelled }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.partiallyPaid:
        return 'Partial';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.draft:
        return AppColors.lightTextSecondary;
      case InvoiceStatus.sent:
        return AppColors.info;
      case InvoiceStatus.partiallyPaid:
        return AppColors.warning;
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.overdue:
        return AppColors.error;
      case InvoiceStatus.cancelled:
        return AppColors.lightTextSecondary;
    }
  }
}

/// A single line item within an invoice.
///
/// Schema: invoice_items(id, invoice_id, user_id, item_name, description,
///   quantity, unit_price, line_total, sort_order, created_at)
class InvoiceLineItem {
  const InvoiceLineItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    this.id,
    this.description,
    this.sortOrder = 0,
    this.createdAt,
  });

  /// Supabase row id. Null for unsaved / locally-created items.
  final String? id;

  /// Primary item name / title shown on the document (maps to item_name in DB).
  final String itemName;

  /// Optional longer description for the line item (maps to description in DB).
  final String? description;
  final double quantity;
  final double unitPrice;
  final int sortOrder;
  final DateTime? createdAt;

  double get lineTotal => quantity * unitPrice;

  /// Alias kept for backward compatibility with code that uses [total].
  double get total => lineTotal;
}

/// Invoice domain entity.
///
/// Schema: invoices(id, user_id, customer_id, source_quotation_id,
///   invoice_number, issue_date, due_date, currency, subtotal,
///   discount_amount, total_amount, amount_paid, balance_due, notes,
///   payment_instructions, status, created_at, updated_at)
class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.status,
    this.userId,
    this.sourceQuotationId,
    this.taxRate = 0,
    this.discountAmount = 0,
    this.amountPaid = 0,
    this.notes,
    this.paymentInstructions,
    this.currency = 'USD',
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  /// Human-readable document number, e.g. "INV-2026-001".
  final String invoiceNumber;

  final String customerId;

  /// Denormalised customer display name for quick rendering.
  final String customerName;

  /// Id of the quotation this invoice was converted from (source_quotation_id).
  final String? sourceQuotationId;

  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> items;
  final InvoiceStatus status;

  /// Tax rate as a fraction (e.g. 0.19 for 19 %). Not stored in schema but
  /// drives [taxAmount] computation.
  final double taxRate;

  /// Flat discount applied before tax.
  final double discountAmount;

  /// Total amount already paid against this invoice.
  final double amountPaid;

  final String? notes;
  final String? paymentInstructions;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
  double get taxAmount => (subtotal - discountAmount) * taxRate;
  double get totalAmount => subtotal - discountAmount + taxAmount;

  /// Alias kept for backward compatibility.
  double get total => totalAmount;

  double get balanceDue => (totalAmount - amountPaid).clamp(0, double.infinity);

  Invoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? sourceQuotationId,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? items,
    InvoiceStatus? status,
    double? taxRate,
    double? discountAmount,
    double? amountPaid,
    String? notes,
    String? paymentInstructions,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      sourceQuotationId: sourceQuotationId ?? this.sourceQuotationId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
